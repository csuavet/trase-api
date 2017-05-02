class ActorAttributes

  def initialize(context, node)
    @context = context
    @node = node
    @node_type = @node.node_type.node_type
    @data = {
      node_name: @node.name,
      summary: 'data missing',
      column_name: @node_type
    }
    (@node.actor_quals + @node.actor_quants + @node.actor_inds).each do |q|
      if q['name'] == 'SOY_'
        @data[:total_soy_2015] = q['value'].to_f / 1000 # TODO hack
      else
        @data[q['name'].downcase] = q['value']
      end
    end

    @data = @data.merge(top_countries)
    @data = @data.merge(top_sources)
    @data = @data.merge(sustainability)
    @data = @data.merge(companies_exporting)
  end

  def result
    {
      data: @data
    }
  end

  def top_countries
    top_nodes_summary(NodeTypeName::COUNTRY, :top_countries)
  end

  def top_sources
    result = {
      included_years: @context.years,
    }
    [NodeTypeName::MUNICIPALITY, NodeTypeName::BIOME, NodeTypeName::STATE].each do |node_type|
      result = result.merge top_nodes_summary(node_type, node_type.downcase)
    end
    {
      top_sources: result
    }
  end

  def sustainability
    {
      sustainability: [
        {group_name: 'Municipalities', node_type: NodeTypeName::MUNICIPALITY},
        {group_name: 'Biomes', node_type: NodeTypeName::BIOME, is_total: true}
      ].map do |group|
        sustainability_for_group(group[:name], group[:node_type], group[:is_total])
      end
    }
  end

  def companies_exporting
    y_indicator = {
      name: 'Soy exported in 2015', unit: 'Tn', type: 'quant', backend_name: 'SOY_'
    }
    x_indicators = [
      {name: 'Land use', unit: 'Ha', type: 'quant', backend_name: 'LAND_USE'},
      {name: 'Territorial Deforestation', unit: 'Ha', type: 'quant', backend_name: 'DEFORESTATION'},
      {name: 'Potential Soy related deforestation', unit: 'Ha', type: 'quant', backend_name: 'POTENTIAL_SOY_RELATED_DEFOR'},
      {name: 'Soy related deforestation', unit: 'Ha', type: 'quant', backend_name: 'AGROSATELITE_SOY_DEFOR_'},
      {name: 'Loss of biodiversity', type: 'quant', backend_name: 'BIODIVERSITY'},
      {name: 'Land-based emissions', unit: 'Tn', type: 'quant', backend_name: 'GHG_'}
    ]

    node_index = NodeType.node_index_for_type(@context, NodeTypeName::EXPORTER)
    nodes_join_clause = ActiveRecord::Base.send(
      :sanitize_sql_array,
      ["JOIN nodes ON nodes.node_id = flows.path[?]",
      node_index]
    )

    production_totals = Node.
      select('nodes.node_id AS node_id, nodes.name, sum(CAST(node_quants.value AS DOUBLE PRECISION)) AS value').
      joins(node_quants: :quant).
      joins('JOIN node_types ON node_types.node_type_id = nodes.node_type_id').
      where('nodes.name NOT LIKE ?', 'UNKNOWN%').
      where('quants.name' => y_indicator[:backend_name]).
      where('node_types.node_type' => NodeTypeName::EXPORTER).
      group('nodes.node_id, nodes.name, quants.name')

    indicator_totals = Flow.
        select('nodes.node_id AS node_id, nodes.name, sum(CAST(flow_quants.value AS DOUBLE PRECISION)) AS value, quants.name AS quant_name').
        joins(nodes_join_clause).
        joins('JOIN node_types ON node_types.node_type_id = nodes.node_type_id').
        joins(flow_quants: :quant).
        where('nodes.name NOT LIKE ?', 'UNKNOWN%').
        where('flows.context_id' => @context.id).
        where('quants.name' => x_indicators.map{ |indicator| indicator[:backend_name] }).
        where('node_types.node_type' => NodeTypeName::EXPORTER).
        group('nodes.node_id, nodes.name, quants.name')

    x_indicator_indexes = Hash[x_indicators.map.each_with_index do |indicator, idx|
      [indicator[:backend_name], idx]
    end]

    indicator_totals_hash = {}
    production_totals.each do |total|
      indicator_totals_hash[total['node_id']] ||= Array.new(x_indicators.size)
    end
    indicator_totals.each do |total|
      indicator_idx = x_indicator_indexes[total['quant_name']]
      if indicator_totals_hash.key?(total['node_id'])
        indicator_totals_hash[total['node_id']][indicator_idx] = total['value']
      end
    end

    exports = production_totals.map do |total|
      {
        name: total['name'],
        y: total['value'].to_f / 1000, # TODO hack
        x: indicator_totals_hash[total['node_id']]
      }
    end

    {
      companies_exporting: {
        dimension_y: y_indicator.slice(:name, :unit),
        dimensions_x: x_indicators.map{ |i| i.slice(:name, :unit) },
        companies: exports
      }
    }
  end

  private

  def top_nodes_summary(node_type, node_list_label)
    top_volume_nodes = FlowStatsForNode.new(@context, @node, node_type)
    top_volume_nodes_by_year = top_volume_nodes.top_volume_nodes_by_year
    {
      node_list_label => {
        lines: top_volume_nodes.top_volume_nodes.map do |node|
          {
            name: node['name'],
            geo_id: node['geo_id'],
            values: @context.years.map do |year|
              top_volume_nodes_by_year.select do |v|
                v['node_id'] == node['node_id'] && v['year'] == year
              end.first['value']
            end
          }
        end
      }
    }
  end

  def risk_indicators
    [
      {name: 'Maximum soy deforestation', unit: 'ha', backend_name: 'DEFORESTATION'},
      {name: 'Soy deforestation', unit: 'ha', backend_name: 'SOY_DEFORESTATION'},
      {name: 'Biodiversity loss', backend_name: 'BIODIVERSITY'}
    ]
  end

  def sustainability_for_group(name, node_type, include_totals)
    group_totals_hash = Hash.new
    top_nodes_in_group = FlowStatsForNode.new(@context, @node, node_type).top_deforestation_nodes
    rows = top_nodes_in_group.map do |node|
      top_nodes = FlowStatsForNode.new(@context, @node, @node_type)
      totals_per_indicator = top_nodes.node_totals_for_quants(
        node['node_id'], node_type, risk_indicators.map{ |i| i[:backend_name] }
      )
      totals_hash = Hash[totals_per_indicator.map{ |t| [t['name'], t['value']] }]
      totals_hash.each do |k, v|
        if group_totals_hash[k]
          group_totals_hash[k] += v
        else
          group_totals_hash[k] = v
        end
      end
      {
        values:
          [
            {
              id: node['node_id'],
              value: node['name']
            }
          ] +
          risk_indicators.map do |quant|
            if totals_hash[quant[:backend_name]]
              {value: totals_hash[quant[:backend_name]]}
            else
              nil
            end
          end
      }
    end
    if include_totals
      rows << {
        is_total: true,
        values: risk_indicators.map do |quant|
          if group_totals_hash[quant[:backend_name]]
            {value: group_totals_hash[quant[:backend_name]]}
          else
            nil
          end
        end
      }
    end
    {
      node_type.downcase => {
        included_columns: [{name: node_type.humanize}] + risk_indicators.map{ |indicator| indicator.slice(:name, :unit) },
        rows: rows
      }
    }
  end
end

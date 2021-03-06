shared_context 'brazil resize by' do
  include_context 'brazil contexts'
  include_context 'quants'

  let!(:resize_by_area) do
    FactoryBot.create(:context_resize_by, resize_attribute: area, tooltip_text: 'area tooltip text', context: context, position: 1)
  end
  let!(:resize_by_land_conflicts) do
    FactoryBot.create(:context_resize_by, resize_attribute: land_conflicts, tooltip_text: 'land conflicts tooltip text', context: context, position: 2)
  end
end

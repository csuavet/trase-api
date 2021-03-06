shared_context 'quals' do
  let(:state) do
    Qual.find_by_name('STATE') ||
      FactoryBot.create(:qual, actor_factsheet: false, place_factsheet: true, place_factsheet_temporal: false, name: 'STATE', frontend_name: 'State')
  end
  let(:biome) do
    Qual.find_by_name('BIOME') ||
      FactoryBot.create(:qual, actor_factsheet: false, place_factsheet: true, place_factsheet_temporal: false, name: 'BIOME', frontend_name: 'Biome')
  end
  let(:zero_deforestation) do
    Qual.find_by_name('ZERO_DEFORESTATION') ||
      FactoryBot.create(:qual, actor_factsheet: true, place_factsheet: false, place_factsheet_temporal: false, name: 'ZERO_DEFORESTATION', frontend_name: 'Zero deforestation commitment (exporters)')
  end
  let(:zero_deforestation_link) do
    Qual.find_by_name('ZERO_DEFORESTATION_LINK') ||
      FactoryBot.create(:qual, actor_factsheet: true, place_factsheet: false, place_factsheet_temporal: false, name: 'ZERO_DEFORESTATION_LINK')
  end
  let(:supply_change) do
    Qual.find_by_name('SUPPLY_CHANGE') ||
      FactoryBot.create(:qual, actor_factsheet: true, place_factsheet: false, place_factsheet_temporal: false, name: 'SUPPLY_CHANGE')
  end
  let(:supply_change_link) do
    Qual.find_by_name('SUPPLY_CHANGE_LINK') ||
      FactoryBot.create(:qual, actor_factsheet: true, place_factsheet: false, place_factsheet_temporal: false, name: 'SUPPLY_CHANGE_LINK')
  end
  let(:rtrs_member) do
    Qual.find_by_name('RTRS_MEMBER') ||
      FactoryBot.create(:qual, actor_factsheet: true, place_factsheet: false, place_factsheet_temporal: false, name: 'RTRS_MEMBER')
  end
end

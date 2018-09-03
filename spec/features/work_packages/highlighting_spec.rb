require 'spec_helper'

describe 'Work Package highlighting fields', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }

  let(:status1) { FactoryBot.create :status, color: FactoryBot.create(:color, hexcode: '#FF0000') }
  let(:status2) { FactoryBot.create :status, color: FactoryBot.create(:color, hexcode: '#F0F0F0') }

  let(:priority1) { FactoryBot.create :status, color: FactoryBot.create(:color, hexcode: '#123456') }
  let(:priority_no_color) { FactoryBot.create :status, color: nil }

  let!(:wp_1) do
    FactoryBot.create :work_package,
                      project: project,
                      status: status1,
                      due_date: (Date.today - 1.days),
                      priority: priority1
  end

  let!(:wp_2) do
    FactoryBot.create :work_package,
                      project: project,
                      status: status2,
                      due_date: Date.today,
                      priority: priority_no_color
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:highlighting) { ::Components::WorkPackages::Highlighting.new impaired: user.impaired }
  let!(:work_package) { FactoryBot.create :work_package, project: project }

  let!(:query) do
    query = FactoryBot.build(:query, user: user, project: project)
    query.column_names = %w[id subject status priority due_date]

    query.save!
    query
  end

  before do
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_work_package_listed wp_1, wp_2
  end

  it 'provides highlighting through css classes' do
    # Default inline highlight
    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)

    ## Status
    status1_field = wp1_row.find(".__hl_inl_status_#{status1.id}")
    expect(status1_field.native.css_value('background-color')).to eq('#FF0000')
    status2_field = wp2_row.find(".__hl_inl_status_#{status2.id}")
    expect(status2_field.native.css_value('background-color')).to eq('#FOFOFO')

    ## Priority
    prio1_field = wp1_row.find(".__hl_inl_priority_#{priority1.id}")
    expect(prio1_field.native.css_value('background-color')).to eq('#123456')
    ## Priority has no color assigned
    prio2_field = wp1_row.find(".__hl_inl_priority_#{priority1.id}")
    expect(prio2_field.native.css_value('background-color')).not_to be_present

    ## Overdue
    expect(wp1_row).to have_selector('.__hl_date_overdue')
    expect(wp2_row).to have_selector('.__hl_date_due_today')

    # Highlight by status
    highlighting.switch_highlight 'Status'
    expect(page).to have_selector("#{wp_table.row_selector(wp_1)}.__hl_row_status_#{status1.id}")
    expect(page).to have_selector("#{wp_table.row_selector(wp_2)}.__hl_row_status_#{status2.id}")
    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)
    expect(wp1_row.native.css_value('background-color')).to eq('#FF0000')
    expect(wp2_row.native.css_value('background-color')).to eq('#F0F0F0')

    ## This disables any inline styles
    expect(page).to have_no_selector('[class*="__hl_inl_status"]')
    expect(page).to have_no_selector('[class*="__hl_inl_priority"]')
    expect(page).to have_no_selector('[class*="__hl_date"]')

    # Highlight by priority
    highlighting.switch_highlight 'Priority'
    expect(page).to have_selector("#{wp_table.row_selector(wp_1)}.__hl_row_priority_#{priority1.id}")
    expect(page).to have_selector("#{wp_table.row_selector(wp_2)}.__hl_row_priority_#{priority_no_color.id}")

    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)
    expect(wp1_row.native.css_value('background-color')).to eq('#1234566')
    expect(wp2_row.native.css_value('background-color')).not_to be_present

    ## This disables any inline styles
    expect(page).to have_no_selector('[class*="__hl_inl_status"]')
    expect(page).to have_no_selector('[class*="__hl_inl_priority"]')
    expect(page).to have_no_selector('[class*="__hl_date"]')

    # Expect highlighted fields in single view
    wp_table.open_full_screen_by_doubleclick wp_1
    expect(page).to have_selector(".wp-status-button .__hl_inl_status_#{status1.id}")
    expect(page).to have_selector(".__hl_inl_priority#{priority1.id}")
  end
end

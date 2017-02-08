FactoryGirl.define do
  factory :routing_constraint, class: Chouette::RoutingConstraint do
    sequence(:name) { |n| "Name: #{n}" }
    comment 'Some comments'
    sequence(:objectid) { |n| "objectid_#{n}" }
    sequence(:codespace) { |n| "codespace_#{n}" }
    lines { build_list :line, 3 }
    stop_areas { build_list :stop_area, 4 }
  end
end
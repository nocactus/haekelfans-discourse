# frozen_string_literal: true

RSpec.describe "haekelfans-timeline plugin" do
  it "is enabled by default" do
    expect(SiteSetting.haekelfans_timeline_enabled).to eq(true)
  end
end

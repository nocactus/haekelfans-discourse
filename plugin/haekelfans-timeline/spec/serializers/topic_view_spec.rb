# frozen_string_literal: true

RSpec.describe "hf velden op de topic-view (deeplinks)" do
  fab!(:user)
  fab!(:topic)
  fab!(:post1) { Fabricate(:post, topic: topic, post_number: 1) }
  fab!(:upload1) { Fabricate(:image_upload, width: 800, height: 600) }

  before { UploadReference.create!(target: post1, upload: upload1) }

  it "levert hf_images en hf_first_post_id" do
    json =
      TopicViewSerializer.new(
        TopicView.new(topic, user),
        scope: Guardian.new(user),
        root: false,
      ).as_json
    expect(json[:hf_first_post_id]).to eq(post1.id)
    expect(json[:hf_images].length).to eq(1)
    expect(json[:hf_images].first[:width]).to eq(800)
  end
end

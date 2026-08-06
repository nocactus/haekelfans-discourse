# frozen_string_literal: true

RSpec.describe HaekelfansTimeline::TimelineData do
  fab!(:user)
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:post1) { Fabricate(:post, topic: topic, user: user, post_number: 1) }
  fab!(:upload1) { Fabricate(:image_upload, width: 1200, height: 800) }
  fab!(:upload2) { Fabricate(:image_upload, width: 600, height: 900) }

  before do
    UploadReference.create!(target: post1, upload: upload1)
    UploadReference.create!(target: post1, upload: upload2)
  end

  describe ".images_for" do
    it "levert first-post-afbeeldingen met thumbnail-urls in postvolgorde" do
      described_class.preload([topic])
      images = described_class.images_for(topic)
      expect(images.length).to eq(2)
      expect(images.first[:url]).to eq(UrlHelper.cook_url(upload1.url))
      expect(images.first[:width]).to eq(1200)
    end

    it "respecteert het maximum" do
      SiteSetting.haekelfans_timeline_max_images = 1
      described_class.preload([topic])
      expect(described_class.images_for(topic).length).to eq(1)
    end
  end
end

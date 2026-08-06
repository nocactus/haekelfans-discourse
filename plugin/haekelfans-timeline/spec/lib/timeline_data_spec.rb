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

  describe ".replies_for" do
    it "levert de laatste N replies, oudste eerst, met excerpt en teller" do
      SiteSetting.haekelfans_timeline_reply_preview_count = 2
      Fabricate(:post, topic: topic, post_number: 2, raw: "Erste Antwort hier")
      Fabricate(:post, topic: topic, post_number: 3, raw: "Zweite Antwort hier")
      Fabricate(
        :post,
        topic: topic,
        post_number: 4,
        raw: "Dritte Antwort hier",
        reply_to_post_number: 2,
      )
      described_class.preload([topic])
      replies = described_class.replies_for(topic)
      expect(replies.map { |r| r[:post_number] }).to eq([3, 4])
      expect(replies.last[:reply_to_post_number]).to eq(2)
      expect(replies.last[:excerpt]).to include("Dritte")
      expect(described_class.reply_total_for(topic)).to eq(3)
    end

    it "slaat verwijderde posts over" do
      p2 = Fabricate(:post, topic: topic, post_number: 2)
      p2.trash!
      described_class.preload([topic])
      expect(described_class.replies_for(topic)).to eq([])
      expect(described_class.reply_total_for(topic)).to eq(0)
    end
  end
end

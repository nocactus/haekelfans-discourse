# frozen_string_literal: true

RSpec.describe HaekelfansTimeline::TimelineController do
  fab!(:user)

  describe "#tree" do
    fab!(:topic)
    fab!(:op) { Fabricate(:post, topic: topic, post_number: 1) }
    fab!(:r2) { Fabricate(:post, topic: topic, post_number: 2) }

    it "levert de boom voor zichtbare topics" do
      sign_in(user)
      get "/haekelfans/topic/#{topic.id}/tree.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["replies"].first["post_number"]).to eq(2)
    end

    it "weigert topics in onzichtbare categorieën" do
      group = Fabricate(:group)
      category = Fabricate(:private_category, group: group)
      secret = Fabricate(:topic, category: category)
      Fabricate(:post, topic: secret, post_number: 1)
      sign_in(user)
      get "/haekelfans/topic/#{secret.id}/tree.json"
      expect(response.status).to eq(403)
    end

    it "geeft 404 voor onbekend topic" do
      sign_in(user)
      get "/haekelfans/topic/999999/tree.json"
      expect(response.status).to eq(404)
    end
  end
end

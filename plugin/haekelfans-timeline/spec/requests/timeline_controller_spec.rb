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

  describe "#online" do
    fab!(:online_user) { Fabricate(:user, last_seen_at: 2.minutes.ago) }
    fab!(:offline_user) { Fabricate(:user, last_seen_at: 2.hours.ago) }

    before { Discourse.cache.delete("haekelfans_online") }

    it "telt alleen recent geziene leden" do
      sign_in(user)
      get "/haekelfans/online.json"
      expect(response.status).to eq(200)
      usernames = response.parsed_body["users"].map { |u| u["username"] }
      expect(usernames).to include(online_user.username)
      expect(usernames).not_to include(offline_user.username)
      expect(response.parsed_body["count"]).to be >= 1
    end

    it "weigert anoniem" do
      get "/haekelfans/online.json"
      expect(response.status).to eq(403)
    end
  end
end

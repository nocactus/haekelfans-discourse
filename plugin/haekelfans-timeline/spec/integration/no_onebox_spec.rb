# frozen_string_literal: true

RSpec.describe "hf_no_onebox" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }

  it "bewaart de vlag vanuit het create-param" do
    post =
      PostCreator.create!(
        user,
        title: "Ein Beitrag mit Link",
        raw: "Schau mal https://haekelfans.de hier",
        hf_no_onebox: "true",
      )
    expect(post.reload.custom_fields["hf_no_onebox"]).to eq(true)
  end

  it "stript oneboxes uit de cooked html wanneer de vlag gezet is" do
    post =
      PostCreator.create!(
        user,
        title: "Noch ein Beitrag mit Link",
        raw: "zie link",
        hf_no_onebox: "true",
      )
    post.update_columns(
      cooked:
        %{<aside class="onebox" data-onebox-src="https://haekelfans.de"><a href="https://haekelfans.de">Häkelfans</a></aside>},
    )
    doc = Nokogiri::HTML5.fragment(post.cooked)
    DiscourseEvent.trigger(:post_process_cooked, doc, post.reload)
    expect(doc.to_html).not_to include("onebox")
    expect(doc.to_html).to include(%{<a href="https://haekelfans.de"})
  end

  it "laat oneboxes staan zonder vlag" do
    post =
      PostCreator.create!(user, title: "Beitrag ohne Vlag setzen", raw: "gewoon een bericht")
    post.update_columns(
      cooked: %{<aside class="onebox"><a href="https://haekelfans.de">x</a></aside>},
    )
    doc = Nokogiri::HTML5.fragment(post.cooked)
    DiscourseEvent.trigger(:post_process_cooked, doc, post.reload)
    expect(doc.to_html).to include("onebox")
  end

  describe "bij bewerken" do
    fab!(:post) { Fabricate(:post, user: user, raw: "Kijk https://haekelfans.de eens") }

    it "zet de vlag en rendert opnieuw zonder tekstwijziging" do
      sign_in(user)
      put "/posts/#{post.id}.json", params: { post: { raw: post.raw, hf_no_onebox: "true" } }
      expect(response.status).to eq(200)
      expect(post.reload.custom_fields["hf_no_onebox"]).to eq(true)
    end

    it "haalt de vlag weg" do
      post.custom_fields["hf_no_onebox"] = true
      post.save_custom_fields
      sign_in(user)
      put "/posts/#{post.id}.json", params: { post: { raw: post.raw, hf_no_onebox: "false" } }
      expect(post.reload.custom_fields["hf_no_onebox"]).to be_nil
    end

    it "toont de vlag in de post-serializer" do
      post.custom_fields["hf_no_onebox"] = true
      post.save_custom_fields
      sign_in(user)
      get "/posts/#{post.id}.json"
      expect(response.parsed_body["hf_no_onebox"]).to eq(true)
    end
  end
end

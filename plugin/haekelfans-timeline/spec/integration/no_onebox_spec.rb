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
end

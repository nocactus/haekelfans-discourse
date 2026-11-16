# frozen_string_literal: true

RSpec.describe HaekelfansTimeline::ReplyTree do
  fab!(:topic)
  fab!(:op) { Fabricate(:post, topic: topic, post_number: 1) }

  def reply(to:, n:)
    Fabricate(:post, topic: topic, post_number: n, reply_to_post_number: to, raw: "Antwort #{n}")
  end

  it "nest replies en kapt op 4 niveaus" do
    reply(to: nil, n: 2) # niveau 1
    reply(to: 2, n: 3)   # niveau 2
    reply(to: 3, n: 4)   # niveau 3
    reply(to: 4, n: 5)   # niveau 4
    reply(to: 5, n: 6)   # niveau 5 -> platgeslagen naar 4
    tree = described_class.build(topic.reload, Guardian.new)
    root = tree[:replies].first
    expect(root[:post_number]).to eq(2)
    l4 = root[:children].first[:children].first[:children]
    expect(l4.map { |node| node[:post_number] }).to contain_exactly(5, 6)
    expect(l4.flat_map { |node| node[:children] }).to eq([])
  end

  it "levert de naam van degene op wie gereageerd wordt" do
    parent = reply(to: nil, n: 2)
    parent.user.update!(name: "Manuela Seydler")
    child = reply(to: 2, n: 3)
    child.update_columns(reply_to_user_id: parent.user_id)
    tree = described_class.build(topic.reload, Guardian.new)
    node = tree[:replies].first[:children].first
    expect(node[:reply_to_name]).to eq("Manuela Seydler")
    expect(tree[:replies].first[:reply_to_name]).to be_nil
  end

  it "pagineert top-level replies" do
    reply(to: nil, n: 2)
    reply(to: nil, n: 3)
    stub_const(HaekelfansTimeline::ReplyTree, :PER_PAGE, 1) do
      page0 = described_class.build(topic.reload, Guardian.new, page: 0)
      page1 = described_class.build(topic.reload, Guardian.new, page: 1)
      expect(page0[:total]).to eq(2)
      expect(page0[:replies].map { |r| r[:post_number] }).to eq([2])
      expect(page1[:replies].map { |r| r[:post_number] }).to eq([3])
    end
  end
end

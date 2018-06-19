require 'rails_helper'

describe 'integration tests' do
  before do
    SiteSetting.assign_enabled = true
  end

  it 'preloads data in topic list' do
    admin = Fabricate(:admin)
    post = create_post
    list = TopicList.new("latest", admin, [post.topic])
    TopicList.preload([post.topic], list)
    # should not explode for now
  end

  describe 'for a private message' do
    let(:post) { Fabricate(:private_message_post) }
    let(:pm) { post.topic }
    let(:user) { pm.allowed_users.first }
    let(:user2) { pm.allowed_users.last }
    let(:channel) { "/private-messages/assigned" }

    def assert_publish_topic_state(topic, user)
      messages = MessageBus.track_publish do
        yield
      end

      message = messages.find { |message| message.channel == channel }

      expect(message.data[:topic_id]).to eq(topic.id)
      expect(message.user_ids).to eq([user.id])
    end

    it 'publishes the right message on archive and move to inbox' do
      assigner = TopicAssigner.new(pm, user)
      assigner.assign(user)

      assert_publish_topic_state(pm, user) do
        UserArchivedMessage.archive!(user.id, pm.reload)
      end

      assert_publish_topic_state(pm, user) do
        UserArchivedMessage.move_to_inbox!(user.id, pm.reload)
      end
    end
  end
end

require 'test_helper'

class AttachmentDraftStatusIntegrationTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  context 'when draft document with file attachment is published' do
    before do
      @edition = create(:news_article)
      @edition.attachments << FactoryBot.build(
        :file_attachment,
        attachable: @edition,
        file: File.open(fixture_path.join('whitepaper.pdf'))
      )

      stub_whitehall_asset('whitepaper.pdf', id: 'asset-id', draft: true)
      stub_whitehall_asset('thumbnail_whitepaper.pdf.png', id: 'thumbnail-asset-id', draft: true)
    end

    test 'attachment & its thumbnail are marked as published in Asset Manager' do
      Services.asset_manager.expects(:update_asset).with('asset-id', 'draft' => false)
      Services.asset_manager.expects(:update_asset).with('thumbnail-asset-id', 'draft' => false)

      force_publisher = Whitehall.edition_services.force_publisher(@edition)
      assert force_publisher.perform!, force_publisher.failure_reason
    end
  end

  context 'when published document with file attachment is unpublished' do
    before do
      @edition = create(:published_news_article)
      @edition.attachments << FactoryBot.build(
        :file_attachment,
        attachable: @edition,
        file: File.open(fixture_path.join('whitepaper.pdf'))
      )

      stub_whitehall_asset('whitepaper.pdf', id: 'asset-id', draft: false)
      stub_whitehall_asset('thumbnail_whitepaper.pdf.png', id: 'thumbnail-asset-id', draft: false)
    end

    test 'attachment & its thumbnail are marked as draft in Asset Manager' do
      Services.asset_manager.expects(:update_asset).with('asset-id', 'draft' => true)
      Services.asset_manager.expects(:update_asset).with('thumbnail-asset-id', 'draft' => true)

      unpublisher = Whitehall.edition_services.unpublisher(@edition, unpublishing: {
        unpublishing_reason: UnpublishingReason::PublishedInError
      })
      assert unpublisher.perform!, unpublisher.failure_reason
    end
  end

  context 'when draft consultation with outcome with file attachment is published' do
    before do
      @edition = create(:draft_consultation)
      outcome = @edition.create_outcome!(FactoryBot.attributes_for(:consultation_outcome))
      outcome.attachments << FactoryBot.build(
        :file_attachment,
        attachable: outcome,
        file: File.open(fixture_path.join('whitepaper.pdf'))
      )

      stub_whitehall_asset('whitepaper.pdf', id: 'asset-id', draft: true)
      stub_whitehall_asset('thumbnail_whitepaper.pdf.png', id: 'thumbnail-asset-id', draft: true)
    end

    test 'attachment & its thumbnail are marked as published in Asset Manager' do
      Services.asset_manager.expects(:update_asset).with('asset-id', 'draft' => false)
      Services.asset_manager.expects(:update_asset).with('thumbnail-asset-id', 'draft' => false)

      force_publisher = Whitehall.edition_services.force_publisher(@edition)
      assert force_publisher.perform!, force_publisher.failure_reason
    end
  end

  context 'when draft consultation with feedback with file attachment is published' do
    before do
      @edition = create(:draft_consultation)
      feedback = @edition.create_public_feedback!(FactoryBot.attributes_for(:consultation_public_feedback))
      feedback.attachments << FactoryBot.build(
        :file_attachment,
        attachable: feedback,
        file: File.open(fixture_path.join('whitepaper.pdf'))
      )

      stub_whitehall_asset('whitepaper.pdf', id: 'asset-id', draft: true)
      stub_whitehall_asset('thumbnail_whitepaper.pdf.png', id: 'thumbnail-asset-id', draft: true)
    end

    test 'attachment & its thumbnail are marked as published in Asset Manager' do
      Services.asset_manager.expects(:update_asset).with('asset-id', 'draft' => false)
      Services.asset_manager.expects(:update_asset).with('thumbnail-asset-id', 'draft' => false)

      force_publisher = Whitehall.edition_services.force_publisher(@edition)
      assert force_publisher.perform!, force_publisher.failure_reason
    end
  end

  context 'when file attachment is added to outcome belonging to published consultation' do
    before do
      edition = create(:published_consultation)
      @outcome = edition.create_outcome!(FactoryBot.attributes_for(:consultation_outcome))

      stub_whitehall_asset('whitepaper.pdf', id: 'asset-id', draft: true)
      stub_whitehall_asset('thumbnail_whitepaper.pdf.png', id: 'thumbnail-asset-id', draft: true)
    end

    test 'attachment & its thumbnail are marked as published in Asset Manager' do
      Services.asset_manager.expects(:update_asset).with('asset-id', 'draft' => false)
      Services.asset_manager.expects(:update_asset).with('thumbnail-asset-id', 'draft' => false)

      @outcome.attachments << FactoryBot.build(
        :file_attachment,
        attachable: @outcome,
        file: File.open(fixture_path.join('whitepaper.pdf'))
      )
      Whitehall.consultation_response_notifier.publish('update', @outcome)
    end
  end

  context 'when file attachment is added to policy group' do
    before do
      @policy_group = create(:policy_group)

      stub_whitehall_asset('whitepaper.pdf', id: 'asset-id', draft: true)
      stub_whitehall_asset('thumbnail_whitepaper.pdf.png', id: 'thumbnail-asset-id', draft: true)
    end

    test 'attachment & its thumbnail are marked as published in Asset Manager' do
      Services.asset_manager.expects(:update_asset).with('asset-id', 'draft' => false)
      Services.asset_manager.expects(:update_asset).with('thumbnail-asset-id', 'draft' => false)

      @policy_group.attachments << FactoryBot.build(
        :file_attachment,
        attachable: @policy_group,
        file: File.open(fixture_path.join('whitepaper.pdf'))
      )
      Whitehall.policy_group_notifier.publish('update', @policy_group)
    end
  end

private

  def ends_with(expected)
    ->(actual) { actual.end_with?(expected) }
  end

  def stub_whitehall_asset(filename, id:, draft:)
    Services.asset_manager.stubs(:whitehall_asset)
      .with(&ends_with(filename))
      .returns('id' => "http://asset-manager/assets/#{id}", 'draft' => draft)
  end
end

# frozen_string_literal: true

class Api::V2::MediaController < Api::V1::MediaController
  def create
    unless supported_mime_type?(params["file"].content_type)
      render json: file_type_error, status: 415
      return
    end

    @media_attachment = current_account.media_attachments.create!(media_and_delay_params)

    render json: @media_attachment, serializer: REST::MediaAttachmentSerializer, status: status_from_media_processing
  rescue Paperclip::Errors::NotIdentifiedByImageMagickError
    render json: file_type_error, status: 422
  rescue Paperclip::Error => e
    Rails.logger.error "#{e.class}: #{e.message}"
    render json: processing_error, status: 500
  end

  private

  def media_and_delay_params
    { delay_processing: true }.merge(media_attachment_params)
  end

  def status_from_media_processing
    @media_attachment.not_processed? ? 202 : 200
  end

  def supported_mime_type?(content_type)
    MediaAttachment::VIDEO_MIME_TYPES.include?(content_type) ||
      MediaAttachment::AUDIO_MIME_TYPES.include?(content_type) ||
      MediaAttachment::IMAGE_MIME_TYPES.include?(content_type)
  end
end

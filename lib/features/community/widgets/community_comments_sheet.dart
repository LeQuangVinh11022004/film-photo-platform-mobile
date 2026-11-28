import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../models/blog_post.dart';
import '../models/community_post_api_models.dart';
import '../services/community_post_api_service.dart';

Future<void> showCommunityCommentsSheet({
  required BuildContext context,
  required BlogPost post,
  required CommunityPostApiService apiService,
  required ValueChanged<int> onCommentsCountChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CommunityCommentsSheetContent(
      post: post,
      apiService: apiService,
      onCommentsCountChanged: onCommentsCountChanged,
    ),
  );
}

class _CommunityCommentsSheetContent extends StatefulWidget {
  final BlogPost post;
  final CommunityPostApiService apiService;
  final ValueChanged<int> onCommentsCountChanged;

  const _CommunityCommentsSheetContent({
    required this.post,
    required this.apiService,
    required this.onCommentsCountChanged,
  });

  @override
  State<_CommunityCommentsSheetContent> createState() =>
      _CommunityCommentsSheetContentState();
}

class _CommunityCommentsSheetContentState
    extends State<_CommunityCommentsSheetContent> {
  final TextEditingController _commentController = TextEditingController();

  List<CommunityCommentResponseDTO> _apiComments = [];
  late bool _isLoadingComments;
  bool _commentsError = false;
  bool _isSending = false;
  CommunityCommentResponseDTO? _replyingTo;
  CommunityCommentResponseDTO? _editingComment;

  bool get _isLiveCommunityPost =>
      widget.post.isCommunityPost && widget.post.id.length >= 32;

  @override
  void initState() {
    super.initState();
    _isLoadingComments = _isLiveCommunityPost;
    if (_isLiveCommunityPost) {
      _fetchLiveComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveComments() async {
    if (!_isLiveCommunityPost || !mounted) return;
    setState(() => _isLoadingComments = true);
    final page = await widget.apiService.getComments(
      postId: widget.post.id,
      page: 1,
      pageSize: 50,
    );
    if (!mounted) return;
    setState(() {
      _commentsError = page == null;
      if (page != null) _apiComments = page.items;
      _isLoadingComments = false;
    });
    if (page != null) {
      final count = page.totalCount > 0 ? page.totalCount : _apiComments.length;
      widget.onCommentsCountChanged(count);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || !_isLiveCommunityPost) return;

    setState(() => _isSending = true);
    final Map<String, dynamic> res;
    if (_editingComment != null) {
      res = await widget.apiService.updateComment(
        postId: widget.post.id,
        commentId: _editingComment!.commentId,
        content: text,
      );
    } else {
      res = await widget.apiService.createComment(
        postId: widget.post.id,
        request: CommunityCommentWriteRequestDTO(
          content: text,
          parentCommentId: _replyingTo?.commentId,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (res['success'] == true) {
        _replyingTo = null;
        _editingComment = null;
      }
    });

    if (res['success'] == true) {
      _commentController.clear();
      await _fetchLiveComments();
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Không thể gửi bình luận'),
        description: Text(res['message']?.toString() ?? ''),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final maxAvailableHeight =
        math.max(240.0, screenHeight - topPadding - bottomInset - 20);
    final sheetHeight = math.min(screenHeight * 0.72, maxAvailableHeight);
    final totalDisplayCount = _apiComments.length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bình Luận ($totalDisplayCount)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
                if (_isLiveCommunityPost)
                  IconButton(
                    tooltip: 'Tải lại bình luận',
                    onPressed: _fetchLiveComments,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLiveCommunityPost
                  ? (_isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : _commentsError
                          ? Center(
                              child: TextButton(
                                onPressed: _fetchLiveComments,
                                child: const Text(
                                  'Không thể tải bình luận. Nhấn để thử lại.',
                                ),
                              ),
                            )
                          : _apiComments.isEmpty
                              ? Center(
                                  child: Text(
                                    'Chưa có bình luận nào. Hãy là người đầu tiên chia sẻ ý kiến!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.textSecColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _apiComments.length,
                                  separatorBuilder: (_, _) =>
                                      Divider(color: context.inputColor),
                                  itemBuilder: (_, index) {
                                    final c = _apiComments[index];
                                    return _CommentItemTile(
                                      comment: c,
                                      onReplyTap: () {
                                        setState(() {
                                          _editingComment = null;
                                          _replyingTo = c;
                                        });
                                      },
                                      onEditTap: () {
                                        setState(() {
                                          _replyingTo = null;
                                          _editingComment = c;
                                          _commentController.text = c.content;
                                        });
                                      },
                                      onDeleteTap: () async {
                                        final ok =
                                            await widget.apiService.deleteComment(
                                          postId: widget.post.id,
                                          commentId: c.commentId,
                                        );
                                        if (ok) {
                                          await _fetchLiveComments();
                                        }
                                      },
                                    );
                                  },
                                ))
                  : const Center(
                      child: Text(
                        'Chưa có bình luận nào cho bài viết này.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
            ),
            if (_replyingTo != null || _editingComment != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _editingComment != null
                          ? Icons.edit_outlined
                          : Icons.reply_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _editingComment != null
                            ? 'Đang sửa bình luận của bạn'
                            : 'Đang trả lời ${_replyingTo!.authorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingTo = null;
                          if (_editingComment != null) {
                            _editingComment = null;
                            _commentController.clear();
                          }
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: _editingComment != null
                            ? 'Nhập nội dung bình luận mới...'
                            : (_replyingTo != null
                                ? 'Trả lời ${_replyingTo!.authorName}...'
                                : 'Viết bình luận...'),
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: context.inputColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isSending ? null : _sendComment,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: context.cardColor,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentItemTile extends StatelessWidget {
  final CommunityCommentResponseDTO comment;
  final VoidCallback onReplyTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _CommentItemTile({
    required this.comment,
    required this.onReplyTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReply =
        comment.parentCommentId != null && comment.parentCommentId!.isNotEmpty;
    final initial =
        comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'U';

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 28.0 : 0.0,
        top: 10.0,
        bottom: 10.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 16 : 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isReply ? 12 : 14,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            comment.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              comment.authorRole
                                      .toUpperCase()
                                      .contains('EXPERT')
                                  ? 'Chuyên gia'
                                  : 'Photographer',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CommunityPostResponseDTO.formatTimeAgo(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    GestureDetector(
                      onTap: onReplyTap,
                      child: const Text(
                        'Trả lời',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (comment.isMine) ...[
                      GestureDetector(
                        onTap: onEditTap,
                        child: Text(
                          'Sửa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textSecColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDeleteTap,
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Heart, ThumbsUp, Flame, MessageCircle, Plus, Settings, Send, X, Image as ImageIcon, Camera, Bell } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { Screen, UserType } from '../../App';
import { BottomNav } from '../BottomNav';

interface CommunityFeedScreenProps {
  onNavigate: (screen: Screen) => void;
  userType?: UserType;
}

interface Comment {
  id: number;
  user: {
    name: string;
    avatar: string;
  };
  text: string;
  timestamp: string;
  replies?: Reply[];
}

interface Reply {
  id: number;
  user: {
    name: string;
    avatar: string;
  };
  text: string;
  timestamp: string;
}

interface Post {
  id: number;
  user: {
    name: string;
    avatar: string;
  };
  image: string;
  text: string;
  timestamp: string;
  reactions: {
    heart: number;
    thumbsUp: number;
    fire: number;
  };
  comments: Comment[];
}

const initialPosts: Post[] = [
  {
    id: 1,
    user: {
      name: 'Sarah M.',
      avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400',
    },
    image: 'https://images.unsplash.com/photo-1734989175071-fedc119fb52e?w=800',
    text: 'Healthy lunch today! 🥗 Feeling energized and ready to crush my afternoon goals.',
    timestamp: '2 hours ago',
    reactions: { heart: 24, thumbsUp: 18, fire: 12 },
    comments: [
      {
        id: 1,
        user: { name: 'Mike R.', avatar: 'https://i.pravatar.cc/150?img=12' },
        text: 'Looks delicious! What\'s in it?',
        timestamp: '1 hour ago',
        replies: [
          {
            id: 1,
            user: { name: 'Sarah M.', avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400' },
            text: 'Quinoa, grilled chicken, avocado, and lots of veggies! 🥑',
            timestamp: '45 min ago'
          }
        ]
      },
      {
        id: 2,
        user: { name: 'Emma L.', avatar: 'https://i.pravatar.cc/150?img=5' },
        text: 'This is inspiring! I need to meal prep better.',
        timestamp: '30 min ago',
        replies: []
      }
    ],
  },
  {
    id: 2,
    user: {
      name: 'Mike R.',
      avatar: 'https://i.pravatar.cc/150?img=12',
    },
    image: 'https://images.unsplash.com/photo-1522845015757-50bce044e5da?w=800',
    text: 'Morning workout done! ✅ 5k run + strength training. Who else got their steps in today?',
    timestamp: '5 hours ago',
    reactions: { heart: 42, thumbsUp: 31, fire: 28 },
    comments: [
      {
        id: 1,
        user: { name: 'Alex K.', avatar: 'https://i.pravatar.cc/150?img=8' },
        text: 'Beast mode! 💪 I did a 3k this morning.',
        timestamp: '4 hours ago',
        replies: []
      }
    ],
  },
  {
    id: 3,
    user: {
      name: 'Emma L.',
      avatar: 'https://i.pravatar.cc/150?img=5',
    },
    image: '',
    text: '8 hours of sleep for the first time this week! 😴 Small wins matter. Thank you Gravity for the reminder notifications!',
    timestamp: '8 hours ago',
    reactions: { heart: 35, thumbsUp: 22, fire: 15 },
    comments: [
      {
        id: 1,
        user: { name: 'Sarah M.', avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400' },
        text: 'Sleep is so important! Great job! 🌙',
        timestamp: '7 hours ago',
        replies: []
      }
    ],
  },
  {
    id: 4,
    user: {
      name: 'Alex K.',
      avatar: 'https://i.pravatar.cc/150?img=8',
    },
    image: 'https://images.unsplash.com/photo-1734989175071-fedc119fb52e?w=800',
    text: 'Meal prep Sunday! 🍱 Planning my week ahead. Consistency is key!',
    timestamp: '1 day ago',
    reactions: { heart: 28, thumbsUp: 19, fire: 14 },
    comments: [],
  },
];

export function CommunityFeedScreen({ onNavigate, userType }: CommunityFeedScreenProps) {
  const [posts, setPosts] = useState<Post[]>(initialPosts);
  const [activeReactions, setActiveReactions] = useState<Record<number, Set<string>>>({});
  const [selectedPostId, setSelectedPostId] = useState<number | null>(null);
  const [newComment, setNewComment] = useState('');
  const [replyingTo, setReplyingTo] = useState<{ postId: number; commentId: number } | null>(null);
  const [newReply, setNewReply] = useState('');
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [newPostText, setNewPostText] = useState('');
  const [selectedImage, setSelectedImage] = useState<string>('');

  const toggleReaction = (postId: number, reaction: string) => {
    setActiveReactions(prev => {
      const postReactions = new Set(prev[postId] || []);
      
      // Check if user already has this exact reaction
      const hasThisReaction = postReactions.has(reaction);
      
      // Get the previous reaction if user had one
      const previousReaction = postReactions.size > 0 ? Array.from(postReactions)[0] : null;
      
      // Clear all reactions for this post (since user can only have one)
      postReactions.clear();
      
      // If clicking the same reaction, remove it (toggle off)
      // If clicking a different reaction, add the new one
      if (!hasThisReaction) {
        postReactions.add(reaction);
      }
      
      // Update the post's reaction count
      setPosts(prevPosts => prevPosts.map(post => {
        if (post.id === postId) {
          const updatedReactions = { ...post.reactions };
          
          // Decrement previous reaction if user had one
          if (previousReaction) {
            if (previousReaction === 'heart') {
              updatedReactions.heart = Math.max(0, updatedReactions.heart - 1);
            } else if (previousReaction === 'thumbsUp') {
              updatedReactions.thumbsUp = Math.max(0, updatedReactions.thumbsUp - 1);
            } else if (previousReaction === 'fire') {
              updatedReactions.fire = Math.max(0, updatedReactions.fire - 1);
            }
          }
          
          // Increment new reaction if user is adding one (not removing)
          if (!hasThisReaction) {
            if (reaction === 'heart') {
              updatedReactions.heart = updatedReactions.heart + 1;
            } else if (reaction === 'thumbsUp') {
              updatedReactions.thumbsUp = updatedReactions.thumbsUp + 1;
            } else if (reaction === 'fire') {
              updatedReactions.fire = updatedReactions.fire + 1;
            }
          }
          
          return { ...post, reactions: updatedReactions };
        }
        return post;
      }));
      
      return { ...prev, [postId]: postReactions };
    });
  };

  const handleAddComment = (postId: number) => {
    if (!newComment.trim()) return;

    setPosts(prev => prev.map(post => {
      if (post.id === postId) {
        const newCommentObj: Comment = {
          id: post.comments.length + 1,
          user: {
            name: 'You',
            avatar: 'https://i.pravatar.cc/150?img=1',
          },
          text: newComment,
          timestamp: 'Just now',
          replies: []
        };
        return {
          ...post,
          comments: [...post.comments, newCommentObj]
        };
      }
      return post;
    }));
    setNewComment('');
  };

  const handleAddReply = (postId: number, commentId: number) => {
    if (!newReply.trim()) return;

    setPosts(prev => prev.map(post => {
      if (post.id === postId) {
        return {
          ...post,
          comments: post.comments.map(comment => {
            if (comment.id === commentId) {
              const newReplyObj: Reply = {
                id: (comment.replies?.length || 0) + 1,
                user: {
                  name: 'You',
                  avatar: 'https://i.pravatar.cc/150?img=1',
                },
                text: newReply,
                timestamp: 'Just now'
              };
              return {
                ...comment,
                replies: [...(comment.replies || []), newReplyObj]
              };
            }
            return comment;
          })
        };
      }
      return post;
    }));
    setNewReply('');
    setReplyingTo(null);
  };

  const selectedPost = posts.find(p => p.id === selectedPostId);

  const sampleImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
  ];

  const handleCreatePost = () => {
    if (!newPostText.trim()) return;

    const newPost: Post = {
      id: Math.max(...posts.map(p => p.id)) + 1,
      user: {
        name: 'You',
        avatar: 'https://i.pravatar.cc/150?img=1',
      },
      image: selectedImage,
      text: newPostText,
      timestamp: 'Just now',
      reactions: { heart: 0, thumbsUp: 0, fire: 0 },
      comments: []
    };

    setPosts([newPost, ...posts]);
    setNewPostText('');
    setSelectedImage('');
    setShowCreatePost(false);
  };

  return (
    <div className="h-full flex flex-col bg-gradient-to-br from-[#F5F6FA] to-white overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0A2342] to-[#00B8A9] px-6 pt-14 pb-6 rounded-b-[40px] sticky top-0 z-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-white">Community</h2>
          <div className="flex items-center gap-2">
            <motion.button
              onClick={() => onNavigate('notifications')}
              className="w-10 h-10 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center relative"
              whileTap={{ scale: 0.9 }}
            >
              <Bell className="w-5 h-5 text-white" />
              <div className="absolute top-2 right-2 w-2 h-2 bg-[#D4AF37] rounded-full" />
            </motion.button>
            <motion.button
              onClick={() => onNavigate('settings')}
              className="w-10 h-10 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center"
              whileTap={{ scale: 0.9 }}
            >
              <Settings className="w-5 h-5 text-white" />
            </motion.button>
          </div>
        </div>
        <p className="text-[#D4AF37]">Share your wellness journey</p>
      </div>

      {/* Feed */}
      <div className="px-6 py-6 space-y-4">
        <AnimatePresence>
          {posts.map((post, index) => (
            <motion.div
              key={post.id}
              className="bg-white rounded-[28px] shadow-md overflow-hidden"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              {/* User Header */}
              <div className="p-5 flex items-center gap-3">
                <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-200">
                  <ImageWithFallback
                    src={post.user.avatar}
                    alt={post.user.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1">
                  <p className="text-[#0A2342]">{post.user.name}</p>
                  <p className="text-[#0A2342]/50 text-xs">{post.timestamp}</p>
                </div>
              </div>

              {/* Post Image */}
              {post.image && (
                <div className="relative h-64 bg-gray-100">
                  <ImageWithFallback
                    src={post.image}
                    alt="Post image"
                    className="w-full h-full object-cover"
                  />
                </div>
              )}

              {/* Post Text */}
              <div className="p-5">
                <p className="text-[#0A2342]/80 mb-4">{post.text}</p>

                {/* Reactions Bar */}
                <div className="flex items-center justify-between pt-4 border-t border-[#0A2342]/10">
                  <div className="flex items-center gap-4">
                    <ReactionButton
                      icon={<Heart className="w-5 h-5" />}
                      count={post.reactions.heart}
                      active={activeReactions[post.id]?.has('heart')}
                      onClick={() => toggleReaction(post.id, 'heart')}
                      activeColor="text-red-500"
                    />
                    <ReactionButton
                      icon={<ThumbsUp className="w-5 h-5" />}
                      count={post.reactions.thumbsUp}
                      active={activeReactions[post.id]?.has('thumbsUp')}
                      onClick={() => toggleReaction(post.id, 'thumbsUp')}
                      activeColor="text-blue-500"
                    />
                    <ReactionButton
                      icon={<Flame className="w-5 h-5" />}
                      count={post.reactions.fire}
                      active={activeReactions[post.id]?.has('fire')}
                      onClick={() => toggleReaction(post.id, 'fire')}
                      activeColor="text-orange-500"
                    />
                  </div>
                  <motion.button
                    onClick={() => setSelectedPostId(post.id)}
                    className="flex items-center gap-2 text-[#0A2342]/60 hover:text-[#00B8A9] transition-colors"
                    whileTap={{ scale: 0.9 }}
                  >
                    <MessageCircle className="w-5 h-5" />
                    <span className="text-sm">{post.comments.length}</span>
                  </motion.button>
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Floating Create Post Button */}
      <motion.button
        onClick={() => setShowCreatePost(true)}
        className="fixed bottom-24 right-6 w-16 h-16 bg-gradient-to-br from-[#00B8A9] to-[#0A2342] rounded-full shadow-lg flex items-center justify-center text-white z-20"
        whileTap={{ scale: 0.9 }}
        whileHover={{ scale: 1.05 }}
      >
        <Plus className="w-8 h-8" />
      </motion.button>

      {/* Create Post Modal */}
      <AnimatePresence>
        {showCreatePost && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 z-[60]"
              onClick={() => {
                setShowCreatePost(false);
                setNewPostText('');
                setSelectedImage('');
              }}
            />

            {/* Modal */}
            <motion.div
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 30, stiffness: 300 }}
              className="fixed bottom-0 left-0 right-0 bg-white rounded-t-[40px] z-[70] max-h-[90vh] flex flex-col"
            >
              {/* Modal Header */}
              <div className="flex items-center justify-between p-6 border-b border-[#0A2342]/10">
                <h3 className="text-[#0A2342]">Create Post</h3>
                <motion.button
                  onClick={() => {
                    setShowCreatePost(false);
                    setNewPostText('');
                    setSelectedImage('');
                  }}
                  className="w-8 h-8 bg-[#0A2342]/10 rounded-full flex items-center justify-center"
                  whileTap={{ scale: 0.9 }}
                >
                  <X className="w-5 h-5 text-[#0A2342]" />
                </motion.button>
              </div>

              {/* User Info */}
              <div className="p-6 border-b border-[#0A2342]/10">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-200">
                    <ImageWithFallback
                      src="https://i.pravatar.cc/150?img=1"
                      alt="Your avatar"
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div>
                    <p className="text-[#0A2342]">You</p>
                    <p className="text-[#0A2342]/50 text-xs">Sharing to Community</p>
                  </div>
                </div>
              </div>

              {/* Post Content */}
              <div className="flex-1 overflow-y-auto p-6 space-y-4">
                {/* Text Input */}
                <textarea
                  value={newPostText}
                  onChange={(e) => setNewPostText(e.target.value)}
                  placeholder="Share your wellness journey..."
                  className="w-full bg-transparent text-[#0A2342] placeholder-[#0A2342]/40 focus:outline-none resize-none min-h-[120px]"
                  autoFocus
                />

                {/* Selected Image Preview */}
                {selectedImage && (
                  <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="relative rounded-[20px] overflow-hidden"
                  >
                    <ImageWithFallback
                      src={selectedImage}
                      alt="Selected"
                      className="w-full h-64 object-cover"
                    />
                    <motion.button
                      onClick={() => setSelectedImage('')}
                      className="absolute top-3 right-3 w-8 h-8 bg-black/50 backdrop-blur-sm rounded-full flex items-center justify-center"
                      whileTap={{ scale: 0.9 }}
                    >
                      <X className="w-4 h-4 text-white" />
                    </motion.button>
                  </motion.div>
                )}

                {/* Image Gallery */}
                {!selectedImage && (
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <ImageIcon className="w-5 h-5 text-[#00B8A9]" />
                      <p className="text-[#0A2342]/60 text-sm">Add a photo to your post</p>
                    </div>
                    <div className="grid grid-cols-3 gap-2">
                      {sampleImages.map((image, index) => (
                        <motion.button
                          key={index}
                          onClick={() => setSelectedImage(image)}
                          className="relative aspect-square rounded-[16px] overflow-hidden bg-gray-100"
                          whileTap={{ scale: 0.95 }}
                        >
                          <ImageWithFallback
                            src={image}
                            alt={`Sample ${index + 1}`}
                            className="w-full h-full object-cover"
                          />
                        </motion.button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Post Button */}
              <div className="p-6 border-t border-[#0A2342]/10 bg-white">
                <motion.button
                  onClick={handleCreatePost}
                  disabled={!newPostText.trim()}
                  className={`w-full py-4 rounded-2xl flex items-center justify-center gap-2 ${
                    newPostText.trim()
                      ? 'bg-gradient-to-br from-[#00B8A9] to-[#0A2342] text-white'
                      : 'bg-[#0A2342]/10 text-[#0A2342]/40'
                  }`}
                  whileTap={{ scale: 0.98 }}
                >
                  <Send className="w-5 h-5" />
                  <span>Share Post</span>
                </motion.button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Comments Modal */}
      <AnimatePresence>
        {selectedPostId && selectedPost && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 z-[60]"
              onClick={() => {
                setSelectedPostId(null);
                setNewComment('');
                setReplyingTo(null);
                setNewReply('');
              }}
            />

            {/* Modal */}
            <motion.div
              initial={{ opacity: 0, y: '100%' }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: '100%' }}
              transition={{ type: 'spring', damping: 30, stiffness: 300 }}
              className="fixed bottom-0 left-0 right-0 bg-white rounded-t-[40px] z-[70] max-h-[85vh] flex flex-col shadow-2xl"
            >
              {/* Modal Header */}
              <div className="flex items-center justify-between p-6 border-b border-[#0A2342]/10 bg-gradient-to-br from-[#0A2342] to-[#00B8A9] rounded-t-[40px]">
                <h3 className="text-white">Comments ({selectedPost.comments.length})</h3>
                <motion.button
                  onClick={() => {
                    setSelectedPostId(null);
                    setNewComment('');
                    setReplyingTo(null);
                    setNewReply('');
                  }}
                  className="w-10 h-10 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center"
                  whileTap={{ scale: 0.9 }}
                >
                  <X className="w-5 h-5 text-white" />
                </motion.button>
              </div>

              {/* Comments List */}
              <div className="flex-1 overflow-y-auto p-6 space-y-6">
                {selectedPost.comments.length === 0 ? (
                  <div className="text-center py-12">
                    <MessageCircle className="w-16 h-16 text-[#0A2342]/20 mx-auto mb-4" />
                    <p className="text-[#0A2342]/40">No comments yet</p>
                    <p className="text-[#0A2342]/30 text-sm mt-2">Be the first to comment!</p>
                  </div>
                ) : (
                  selectedPost.comments.map((comment, index) => (
                    <motion.div
                      key={comment.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: index * 0.05 }}
                      className="space-y-3"
                    >
                      {/* Comment */}
                      <div className="bg-[#F5F6FA] rounded-[20px] p-4">
                        <div className="flex items-start gap-3 mb-2">
                          <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-200 flex-shrink-0">
                            <ImageWithFallback
                              src={comment.user.avatar}
                              alt={comment.user.name}
                              className="w-full h-full object-cover"
                            />
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <p className="text-[#0A2342]">{comment.user.name}</p>
                              <span className="text-[#0A2342]/30 text-xs">•</span>
                              <p className="text-[#0A2342]/50 text-xs">{comment.timestamp}</p>
                            </div>
                            <p className="text-[#0A2342]/80">{comment.text}</p>
                          </div>
                        </div>
                        <motion.button
                          onClick={() => setReplyingTo({ postId: selectedPostId, commentId: comment.id })}
                          className="text-[#00B8A9] text-sm ml-[52px]"
                          whileTap={{ scale: 0.95 }}
                        >
                          Reply
                        </motion.button>
                      </div>

                      {/* Replies */}
                      {comment.replies && comment.replies.length > 0 && (
                        <div className="ml-8 space-y-3">
                          {comment.replies.map((reply, replyIndex) => (
                            <motion.div
                              key={reply.id}
                              initial={{ opacity: 0, x: -10 }}
                              animate={{ opacity: 1, x: 0 }}
                              transition={{ delay: replyIndex * 0.03 }}
                              className="bg-[#F5F6FA] rounded-[20px] p-4"
                            >
                              <div className="flex items-start gap-3">
                                <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-200 flex-shrink-0">
                                  <ImageWithFallback
                                    src={reply.user.avatar}
                                    alt={reply.user.name}
                                    className="w-full h-full object-cover"
                                  />
                                </div>
                                <div className="flex-1">
                                  <div className="flex items-center gap-2 mb-1">
                                    <p className="text-[#0A2342]">{reply.user.name}</p>
                                    <span className="text-[#0A2342]/30 text-xs">•</span>
                                    <p className="text-[#0A2342]/50 text-xs">{reply.timestamp}</p>
                                  </div>
                                  <p className="text-[#0A2342]/80">{reply.text}</p>
                                </div>
                              </div>
                            </motion.div>
                          ))}
                        </div>
                      )}

                      {/* Reply Input */}
                      {replyingTo && replyingTo.postId === selectedPostId && replyingTo.commentId === comment.id && (
                        <motion.div
                          initial={{ opacity: 0, height: 0 }}
                          animate={{ opacity: 1, height: 'auto' }}
                          exit={{ opacity: 0, height: 0 }}
                          className="ml-8 bg-white rounded-[20px] shadow-md p-4"
                        >
                          <div className="flex items-center gap-3 mb-3">
                            <div className="w-8 h-8 rounded-full overflow-hidden bg-gray-200">
                              <ImageWithFallback
                                src="https://i.pravatar.cc/150?img=1"
                                alt="You"
                                className="w-full h-full object-cover"
                              />
                            </div>
                            <p className="text-[#0A2342]/60 text-sm">Replying to {comment.user.name}</p>
                          </div>
                          <textarea
                            value={newReply}
                            onChange={(e) => setNewReply(e.target.value)}
                            placeholder="Write a reply..."
                            className="w-full bg-[#F5F6FA] rounded-xl p-3 text-[#0A2342] placeholder-[#0A2342]/40 focus:outline-none resize-none min-h-[80px]"
                            autoFocus
                          />
                          <div className="flex items-center gap-2 mt-3">
                            <motion.button
                              onClick={() => handleAddReply(selectedPostId, comment.id)}
                              disabled={!newReply.trim()}
                              className={`flex-1 py-3 rounded-xl flex items-center justify-center gap-2 ${
                                newReply.trim()
                                  ? 'bg-gradient-to-br from-[#00B8A9] to-[#0A2342] text-white'
                                  : 'bg-[#0A2342]/10 text-[#0A2342]/40'
                              }`}
                              whileTap={{ scale: 0.98 }}
                            >
                              <Send className="w-4 h-4" />
                              <span>Send</span>
                            </motion.button>
                            <motion.button
                              onClick={() => {
                                setReplyingTo(null);
                                setNewReply('');
                              }}
                              className="px-4 py-3 bg-[#0A2342]/10 rounded-xl text-[#0A2342]/60"
                              whileTap={{ scale: 0.98 }}
                            >
                              Cancel
                            </motion.button>
                          </div>
                        </motion.div>
                      )}
                    </motion.div>
                  ))
                )}
              </div>

              {/* Add Comment Input */}
              <div className="p-6 border-t border-[#0A2342]/10 bg-white">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-200">
                    <ImageWithFallback
                      src="https://i.pravatar.cc/150?img=1"
                      alt="You"
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <input
                    type="text"
                    value={newComment}
                    onChange={(e) => setNewComment(e.target.value)}
                    onKeyPress={(e) => {
                      if (e.key === 'Enter' && newComment.trim()) {
                        handleAddComment(selectedPostId);
                      }
                    }}
                    placeholder="Add a comment..."
                    className="flex-1 bg-[#F5F6FA] rounded-full px-4 py-3 text-[#0A2342] placeholder-[#0A2342]/40 focus:outline-none focus:ring-2 focus:ring-[#00B8A9]/20"
                  />
                  <motion.button
                    onClick={() => handleAddComment(selectedPostId)}
                    disabled={!newComment.trim()}
                    className={`w-12 h-12 rounded-full flex items-center justify-center ${
                      newComment.trim()
                        ? 'bg-gradient-to-br from-[#00B8A9] to-[#0A2342] text-white'
                        : 'bg-[#0A2342]/10 text-[#0A2342]/40'
                    }`}
                    whileTap={{ scale: 0.9 }}
                  >
                    <Send className="w-5 h-5" />
                  </motion.button>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Bottom Navigation */}
      <BottomNav currentScreen="community" onNavigate={onNavigate} userType={userType} />
    </div>
  );
}

interface ReactionButtonProps {
  icon: React.ReactNode;
  count: number;
  active: boolean;
  onClick: () => void;
  activeColor: string;
}

function ReactionButton({ icon, count, active, onClick, activeColor }: ReactionButtonProps) {
  return (
    <motion.button
      onClick={onClick}
      className={`flex items-center gap-2 ${active ? activeColor : 'text-[#0A2342]/60'} hover:text-[#00B8A9] transition-colors`}
      whileTap={{ scale: 0.9 }}
    >
      {icon}
      <span className="text-sm">{count}</span>
    </motion.button>
  );
}
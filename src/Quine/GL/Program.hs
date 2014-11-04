module Quine.GL.Program 
  ( Program(..)
  , createProgram
  , deleteProgram
  , attachShader
  , detachShader
  , attachedShaders
  , numAttachedShaders
  , linkProgram
  , linkStatus
  , validateStatus
  , programInfoLog
  , programIsDeleted
  , numActiveAttributes
  , activeAttributeMaxLength
  , numActiveUniforms
  , activeUniformMaxLength
  , activeAtomicCounterBuffers
  , programBinaryLength
  , programComputeWorkGroupSize
  , transformFeedbackVaryingsMaxLength
  , transformFeedbackBufferMode
  , numTransformFeedbackVaryings
  , geometryVerticesOut
  , geometryInputType
  , geometryOutputType
  ) where

import Control.Applicative
import Control.Monad
import Control.Monad.IO.Class
import qualified Data.ByteString as Strict
import qualified Data.ByteString.Internal as Strict
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Ptr
import Foreign.Storable
import Graphics.GL.Raw.Types
import Graphics.GL.Raw.Profile.Core45
import Quine.GL.Classes
import Quine.GL.Shader

newtype Program = Program GLuint

instance Object Program where
  object (Program p) = p

-- * Creation and Deletion

createProgram :: MonadIO m => m Program
createProgram = liftM Program glCreateProgram

deleteProgram :: MonadIO m => Program -> m ()
deleteProgram = glDeleteProgram . object

-- * Attaching Shaders

attachShader :: MonadIO m => Program -> Shader -> m ()
attachShader (Program p) (Shader s) = glAttachShader p s

detachShader :: MonadIO m => Program -> Shader -> m ()
detachShader (Program p) (Shader s) = glDetachShader p s

-- | @'numAttachedShaders' program@ returns the number of shader objects attached to @program@.
numAttachedShaders :: MonadIO m => Program -> m Int
numAttachedShaders p = fromIntegral `liftM` getProgram1 p GL_ATTACHED_SHADERS

attachedShaders :: MonadIO m => Program -> m [Shader]
attachedShaders p = do
  numShaders <- fromIntegral `liftM` getProgram1 p GL_ATTACHED_SHADERS
  ids <- liftIO $ allocaArray (fromIntegral numShaders) $ \buf -> do
    glGetAttachedShaders (object p) numShaders nullPtr buf
    peekArray (fromIntegral numShaders) buf
  return $ map Shader ids

-- * Properties

getProgram1 :: MonadIO m => Program -> GLenum -> m GLint
getProgram1 s p = liftIO $ alloca $ \q -> glGetProgramiv (object s) p q >> peek q

linkProgram :: MonadIO m => Program -> m ()
linkProgram = glLinkProgram . object

programInfoLog :: MonadIO m => Program -> m Strict.ByteString
programInfoLog p = liftIO $ do
  l <- fromIntegral <$> getProgram1 p GL_INFO_LOG_LENGTH
  if l <= 1
    then return Strict.empty
    else liftIO $ alloca $ \pl -> do
      Strict.createUptoN l $ \ps -> do
        glGetProgramInfoLog (object p) (fromIntegral l) pl (castPtr ps)
        return $ l-1

-- | @'programIsDeleted' program@ returns 'True' if @program@ is currently flagged for deletion, 'False' otherwise.
programIsDeleted :: MonadIO m => Program -> m Bool
programIsDeleted p = (GL_FALSE /=) `liftM` getProgram1 p GL_DELETE_STATUS

-- | @'linkStatus' program@ returns 'True'if the last link operation on @program@ was successful, 'False' otherwise.
linkStatus :: MonadIO m => Program -> m Bool
linkStatus p = (GL_FALSE /=) `liftM` getProgram1 p GL_LINK_STATUS

-- * Validation

-- | @'validateStatus' program@ returns 'True' if the last validation operation on @program@ was successful, and 'False' otherwise.
validateStatus :: MonadIO m => Program -> m Bool
validateStatus p = (GL_FALSE /=) `liftM` getProgram1 p GL_VALIDATE_STATUS

-- * Atomic Counter Buffers

-- | @'activeAtomicCounterBuffers' program@ returns the number of active attribute atomic counter buffers used by @program@.
activeAtomicCounterBuffers :: MonadIO m => Program -> m Int
activeAtomicCounterBuffers p = fromIntegral `liftM` getProgram1 p GL_ACTIVE_ATOMIC_COUNTER_BUFFERS

-- * Attributes

-- data Attribute = Attribute { attributeName :: String, attributeType :: GLenum, attributeSize :: Int }

-- | @'numActiveAttributes' program@ returns the number of active attribute variables for @program@.
numActiveAttributes :: MonadIO m => Program -> m Int
numActiveAttributes p = fromIntegral `liftM` getProgram1 p GL_ACTIVE_ATTRIBUTES

-- | @'activeAttributeMaxLength' program@  returns the length of the longest active attribute name for @program@, including the null termination character (i.e., the size of the character buffer required to store the longest attribute name). If no active attributes exist, 0 is returned.
activeAttributeMaxLength :: MonadIO m => Program -> m Int
activeAttributeMaxLength p = fromIntegral `liftM` getProgram1 p GL_ACTIVE_ATTRIBUTE_MAX_LENGTH

-- * Uniforms

-- | @'numActiveUniforms' returns the number of active uniform variables for @program@.
numActiveUniforms :: MonadIO m => Program -> m Int
numActiveUniforms p = fromIntegral `liftM` getProgram1 p GL_ACTIVE_UNIFORMS

-- | @'activeUniformMaxLength' program@  returns the length of the longest active uniform variable name for @program@, including the null termination character (i.e., the size of the character buffer required to store the longest uniform variable name). If no active uniform variables exist, 0 is returned.
activeUniformMaxLength :: MonadIO m => Program -> m Int
activeUniformMaxLength p = fromIntegral `liftM` getProgram1 p GL_ACTIVE_ATTRIBUTE_MAX_LENGTH

-- * Binary

-- | @'programBinaryLength' program@ return the length of the program binary, in bytes, that will be returned by a call to @glGetProgramBinary@. When a progam's @linkStatus@ is False, its program binary length is 0.
programBinaryLength :: MonadIO m => Program -> m Int
programBinaryLength p = fromIntegral `liftM` getProgram1 p GL_PROGRAM_BINARY_LENGTH

-- * Compute Workgroups

-- | @'programComputeWorkgroupSize' program@ returns three integers containing the local work group size of the compute program as specified by its input layout qualifier(s). @program@ must be the name of a program object that has been previously linked successfully and contains a binary for the compute shader stage.
programComputeWorkGroupSize :: MonadIO m => Program -> m (Int, Int, Int)
programComputeWorkGroupSize (Program p) = liftIO $ allocaArray 3 $ \q -> do
  glGetProgramiv p (GL_COMPUTE_WORK_GROUP_SIZE) q
  a <- peek q
  b <- peekElemOff q 1
  c <- peekElemOff q 2
  return (fromIntegral a, fromIntegral b, fromIntegral c)

-- * Transform Feedback

-- | @'transformFeedbackBufferMode' program@ returns a symbolic constant indicating the buffer mode for @program@ used when transform feedback is active. This may be 'GL_SEPARATE_ATTRIBS' or 'GL_INTERLEAVED_ATTRIBS'.
transformFeedbackBufferMode :: MonadIO m => Program -> m GLenum
transformFeedbackBufferMode p = fromIntegral `liftM` getProgram1 p GL_TRANSFORM_FEEDBACK_BUFFER_MODE

-- | @'numTransformFeedbackVaryings' program@ returns the number of varying variables to capture in transform feedback mode for the @program@.
numTransformFeedbackVaryings :: MonadIO m => Program -> m Int
numTransformFeedbackVaryings p = fromIntegral `liftM` getProgram1 p GL_TRANSFORM_FEEDBACK_VARYINGS

-- | @'transformFeedbackVaryingsMaxLength' program@ returns the length of the longest variable name to be used for transform feedback, including the null-terminator.
transformFeedbackVaryingsMaxLength :: MonadIO m => Program -> m Int
transformFeedbackVaryingsMaxLength p = fromIntegral `liftM` getProgram1 p GL_TRANSFORM_FEEDBACK_VARYINGS

-- * Geometry Shaders

-- | @'geometryVerticesOut' program@ returns the maximum number of vertices that the geometry shader in @program@ will output.
geometryVerticesOut :: MonadIO m => Program -> m Int
geometryVerticesOut p = fromIntegral `liftM` getProgram1 p GL_GEOMETRY_VERTICES_OUT


-- | @'geometryInputType' program@ returns a symbolic constant indicating the primitive type accepted as input to the geometry shader contained in @program@.
geometryInputType :: MonadIO m => Program -> m GLenum
geometryInputType p = fromIntegral `liftM` getProgram1 p GL_GEOMETRY_INPUT_TYPE

-- | @'geometryOutputType' program@ returns a symbolic constant indicating the primitive type that will be output by the geometry shader contained in @program@.
geometryOutputType :: MonadIO m => Program -> m GLenum
geometryOutputType p = fromIntegral `liftM` getProgram1 p GL_GEOMETRY_OUTPUT_TYPE

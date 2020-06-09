{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE ScopedTypeVariables        #-}


module ZIO.Trans (
    EIO, ZIO
  , elift, ezlift, zlift
  , mapEError, mapZError
  , runEIO, runZIO
  , withEIO, withZIO
  , module Control.Monad.Except
  , module Control.Monad.Reader
  , module UnexceptionalIO
  , module UnexceptionalIO.Trans

) where

import           Control.Monad.Except
import           Control.Monad.Fix
import           Control.Monad.IO.Class (MonadIO,)
import           Control.Monad.Reader hiding (lift)
import           Control.Monad.Trans.Class (lift)
import           Control.Monad.Trans.Except
import           Data.Void (Void)
import           UnexceptionalIO hiding (fromIO, lift, run)
import           UnexceptionalIO.Trans (UIO, fromIO, run)

-- | Corresponds to IO[E, A] in Scala
newtype EIO e a = EIO { _unEIO :: ExceptT e UIO a }
  deriving ( Functor, Applicative, Monad, MonadError e, MonadFix, Unexceptional )

newtype ZIO r e a = ZIO { _unZIO :: ReaderT r (EIO e) a }
  deriving ( Functor, Applicative, Monad, MonadError e, MonadFix, MonadReader r, Unexceptional )

type URIO r a = ZIO r Void a

type Task a = forall r. ZIO r SomeNonPseudoException a

type RIO r a = ZIO r SomeNonPseudoException a

elift :: IO a -> EIO SomeNonPseudoException a
elift ioa =  EIO (fromIO ioa)

zlift :: IO a -> ZIO r SomeNonPseudoException a
zlift = ZIO . lift . elift

ezlift :: forall r e a. EIO e a -> ZIO r e a
ezlift = ZIO . lift

runEIO :: MonadIO m => EIO e a -> (e -> m a) -> m a
runEIO eio handler = do
  resEi :: Either e a <- (run . runExceptT . _unEIO) eio
  either handler pure resEi

withEIO :: (e -> e') -> EIO e a -> EIO e' a
withEIO h =  EIO
           . withExceptT h
           . _unEIO

mapEError :: (e -> e') -> EIO e a -> EIO e' a
mapEError = withEIO

runZIO :: MonadIO m => ZIO r e a -> r -> (e -> m a) -> m a
runZIO app env handler = do
  let eio = runReaderT (_unZIO app) env
  runEIO eio handler

withZIO :: r -> (e -> e') -> ZIO r e a -> ZIO r e' a
withZIO r h =  ZIO
             . lift
             . EIO
             . withExceptT h
             . _unEIO
             . flip runReaderT r
             . _unZIO

mapZError :: (e -> e') -> ZIO r e a -> ZIO r e' a
mapZError h m = do
  r <- ask
  withZIO r h m


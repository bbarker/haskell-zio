{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE ScopedTypeVariables        #-}


module ZIO.Trans (
    EIO, ZIO
  , elift, zlift
  , mapError
  , runZIO
  , withZIO
  , module Control.Monad.Reader

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


runZIO :: MonadIO m => ZIO r e a -> r -> (e -> m a) -> m a
runZIO app env handler = do
  let eio = runReaderT (_unZIO app) env
  resEi :: Either e a <- (run . runExceptT . _unEIO) eio
  either handler pure resEi


elift :: IO a -> EIO SomeNonPseudoException a
elift ioa =  EIO (fromIO ioa)

zlift :: IO a -> ZIO r SomeNonPseudoException a
zlift ioa = (ZIO . lift . elift) ioa

withZIO :: r -> (e -> e') -> ZIO r e a -> ZIO r e' a
withZIO r h =  ZIO
             . lift
             . EIO
             . withExceptT h
             . _unEIO
             . flip runReaderT r
             . _unZIO

mapError :: (e -> e') -> ZIO r e a -> ZIO r e' a
mapError h m = do
  r <- ask
  withZIO r h m

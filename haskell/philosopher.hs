
-- http://computationalthoughts.blogspot.com/2008/03/some-examples-of-software-transactional.html

import System.Random (newStdGen, randomR)
import System.Posix (sleep)

import Control.Monad (replicateM)
import Control.Concurrent (forkIO)
import Control.Concurrent.STM (atomically, retry, TVar, STM,
                               newTVar, readTVar, writeTVar)

data Fork = Free | Hold deriving (Show, Eq)
type TFork = TVar Fork

-- WriterT [String] IO Int

main = do
  gen   <- newStdGen
  forks <- atomically forksSTM
  buffer <- atomically (newTVar [])
  for [0..4] `at` \i ->
    forkIO `at` philosopher i buffer (forks !! i) (forks !! ((i + 1) `mod` 5))
  monitor buffer

forksSTM :: STM [TFork]
forksSTM = replicateM 5 newForkSTM

newForkSTM :: STM TFork
newForkSTM = newTVar Free

philosopher :: Int -> TVar [String] -> TFork -> TFork -> IO ()
philosopher n buffer fork0 fork1 = do
  atomically `at` do
    tell buffer ("Philosopher " ++ show n ++ " is eating.")

  atomically `at` do
    eat   fork0
    eat   fork1

  atomically `at` do
    tell buffer ("Philosopher " ++ show n ++ " is thinking.")

  atomically `at` do
    think fork0
    think fork1

  philosopher n buffer fork0 fork1

--

monitor :: TVar [String] -> IO ()
monitor buffer = do
  sentences <- atomically (flush buffer)
  for sentences putStrLn
  monitor buffer

tell :: TVar [String] -> String -> STM ()
tell var sentence = do
  buffer <- readTVar var
  writeTVar var (buffer ++ [sentence])

flush :: TVar [String] -> STM [String]
flush var = do
  buffer <- readTVar var
  case buffer of
    [] -> retry
    _  -> do
      writeTVar var []
      return buffer

--

think :: TFork -> STM ()
think tfork = do
  fork <- readTVar tfork
  case fork of
    Free -> retry
    Hold -> writeTVar tfork Hold

eat :: TFork -> STM ()
eat tfork = do
  fork <- readTVar tfork
  case fork of
    Free -> writeTVar tfork Free
    Hold -> retry

--

for :: (Monad m) => [a] -> (a -> m b) -> m ()
for = flip mapM_

infixr 0 `at`
at :: (a -> b) -> a -> b
f `at` x = f x
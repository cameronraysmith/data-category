{-# LANGUAGE TypeFamilies, TypeOperators, GADTs, FlexibleInstances, FlexibleContexts, RankNTypes, ScopedTypeVariables, UndecidableInstances, NoImplicitPrelude  #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Category.Kleisli
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  sjoerd@w3future.com
-- Stability   :  experimental
-- Portability :  non-portable
--
-- This is an attempt at the Kleisli category, and the construction
-- of an adjunction for each monad.
-----------------------------------------------------------------------------
module Data.Category.Kleisli where
  
import Data.Category
import Data.Category.Functor
import Data.Category.NaturalTransformation
import Data.Category.Monoidal
import qualified Data.Category.Adjunction as A


data Kleisli m a b where
  Kleisli :: (Functor m, Dom m ~ k, Cod m ~ k) => Monad m -> Obj k b -> k a (m :% b) -> Kleisli m a b

kleisliId :: (Functor m, Dom m ~ k, Cod m ~ k) => Monad m -> Obj k a -> Kleisli m a a
kleisliId m a = Kleisli m a (unit m ! a)

-- | The category of Kleisli arrows.
instance Category (Kleisli m) where
  
  src (Kleisli m _ f) = kleisliId m (src f)
  tgt (Kleisli m b _) = kleisliId m b
  
  (Kleisli m c f) . (Kleisli _ _ g) = Kleisli m c ((multiply m ! c) . (monadFunctor m % f) . g)



data KleisliAdjF m = KleisliAdjF (Monad m)
instance (Functor m, Dom m ~ k, Cod m ~ k) => Functor (KleisliAdjF m) where
  type Dom (KleisliAdjF m) = Dom m
  type Cod (KleisliAdjF m) = Kleisli m
  type KleisliAdjF m :% a = a
  KleisliAdjF m % f = Kleisli m (tgt f) ((unit m ! tgt f) . f)
   
data KleisliAdjG m = KleisliAdjG (Monad m)
instance (Functor m, Dom m ~ k, Cod m ~ k) => Functor (KleisliAdjG m) where
  type Dom (KleisliAdjG m) = Kleisli m
  type Cod (KleisliAdjG m) = Dom m
  type KleisliAdjG m :% a = m :% a
  KleisliAdjG m % Kleisli _ b f = (multiply m ! b) . (monadFunctor m % f)

kleisliAdj :: (Functor m, Dom m ~ k, Cod m ~ k)
  => Monad m -> A.Adjunction (Kleisli m) k (KleisliAdjF m) (KleisliAdjG m)
kleisliAdj m = A.mkAdjunctionUnits (KleisliAdjF m) (KleisliAdjG m)
  (\x -> unit m ! x)
  (\(Kleisli _ x _) -> Kleisli m x (monadFunctor m % x))

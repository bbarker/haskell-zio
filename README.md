# haskell-zio

A [small](src/ZIO/Trans.hs) monad-transformer analogue to the
Scala [ZIO](https://github.com/zio/zio)
library (basically, [UIO](http://hackage.haskell.org/package/unexceptionalio) +
[Reader](hackage.haskell.org/package/transformers/docs/Control-Monad-Trans-Reader.html) +
[Either/ExceptT](hackage.haskell.org/package/mtl/docs/Control-Monad-Except.html)).

I like to call `ZIO` a *best-practices monad for applications*. It
wraps in a `Reader` monad for carrying around configuration and
environment data, and slightly more controversially, makes
error-handling more explicit by making all recoverable\
[exceptions and errors](https://wiki.haskell.org/Error_vs._Exception)
part of the return-type of functions.

Note that this is meant to provide the same basic functionality of the `ZIO` monad.
While I'm not immediately looking into other features of ZIO-the-library, such as
concurrency, I welcome suggestions via issues or pull requests.

## Comparison to other Haskell libraries

- [UIO](http://hackage.haskell.org/package/unexceptionalio) This ZIO library
builds upon UIO (Unexceptional-IO) as a dependency, and it is the
inner-most monad in the transformer stack. We use UIO, in conjunction
with `ExceptT`, to model possible error states (or the lack thereof)
more explicitly. In other words, we are trying to make all errors or
exceptions.
[checked exceptions](https://en.wikibooks.org/wiki/Java_Programming/Checked_Exceptions), where possible. See the [blog post](https://singpolyma.net/2018/05/error-handling-in-haskell/) (or [backup](docs/UIO.md)) for more details.
- [RIO](https://hackage.haskell.org/package/rio)
[integrates](hackage.haskell.org/package/rio/docs/src/RIO.Prelude.RIO.html#RIO) `ReaderT` with `IO`, but somewhat like Scala ZIO, provides
much additional functionality, and providing much of that functionality\
will be a goal of haskell-zio as well.
- [Trio](https://github.com/snoyberg/trio) has essentially the same goals
as ZIO (and I believe it is isomorphic to ZIO), but is a self-described
experiment at the moment. The major experimental aspect I'm aware of is
that it is avoiding usage of `ExceptT` to improve performance, which
I have not investigated. We are currently aiming for stability here,
but ideally any code written for haskell-ZIO could easily be transferred
to using `Trio`, or vice versa. If you see a difference, **please raise an
issue** so we can document it or fix it.

## The Scala-Haskell ZIO dictionary

### Type Aliases
The Scala ZIO type parameters and
[aliases](https://zio.dev/docs/overview/overview_index#type-aliases) are
largely reproduced in Haskell, though in some cases we can't exactly
reproduce them. For instance, `IO` is already taken in Haskell at
a very fundamental level. As well, `UIO` has the same meaning as in
the Scala implementation, but it isn't an alias, since it is an inner
monad of the `ZIO` type.

An apparent downsize of having `UIO`, `EIO`, and `ZIO` as distinct
(non-aliased) types is that one might feel inclined to provide APIs
for one or more of these when warranted. For this reason `UEIO e`,
`UZIO a`, and other aliases along with associated lift and unlift
functions are provided. These aliases are most likely only useful
as return values, as the quantification of type variables needs
to be unified across an entire function signature; for instance,
instead of having function like `UEIO a -> UIO a` you would instead
need to write the signature as `EIO Void a -> UIO a`. On the other
hand, a signature that ends like ` -> UEIO a` should be fine.

[//]: # (Table generated from docs/type_aliases.csv using https://www.tablesgenerator.com/markdown_tables)

| Haskell Type 	| Alias for                           	| Scala Type   	| Notes                                                                                                 	|
|--------------	|-------------------------------------	|--------------	|-------------------------------------------------------------------------------------------------------	|
| `ZIO r e a`  	|                                     	| `ZIO[R,E,A]` 	|                                                                                                       	|
| `UIO a`      	|                                     	| `UIO[A]`     	| This is a type alias in Scala but a concrete type in Haskell due to UIO being an inner monadic type.  	|
| `EIO e a`    	|                                     	| `IO[E, A]`   	| This is a type alias in Scala but a concrete type in Haskell due to EIO being an inner monadic type.  	|
| `RIO r a`    	| `ZIO r SomeNonPseudoException a`    	| `RIO[R, A]`  	| Same idea as in Scala. Not to be confused with the RIO library's `RIO` monad, but they are isomorphic. 	|
| `Task a`     	| `ZIO Void SomeNonPseudoException a` 	| `Task[A]`    	|                                                                                                       	|
| `UEIO a`     	| `EIO Void a`                        	| `UIO[A]`     	|                                                                                                       	|
| `URIO r a`   	| `ZIO r Void a`                      	| `URIO[R, A]` 	| Same idea as in Scala; a ZIO value isomorphic to a RIO value (can be projected to the RIO value).     	|
| `UZIO a`     	| `ZIO Void Void a`                   	| `UIO[A]`     	|                                                                                                       	|

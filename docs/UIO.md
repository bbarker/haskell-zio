# UIO

Scala's ZIO was (I have heard from 3rd party sources) inspired by UIO, which
isn't hard to imagine given `UIO` being a type alias for a particular projection
of the ZIO type.


## Error Handling in Haskell

*(This is a backup of the [blog-post](https://singpolyma.net/2018/05/error-handling-in-haskell/)
describing Unexceptional-IO by its author,
Stephen Paul Weber, licensed under [CC By 4.0](http://creativecommons.org/licenses/by/4.0/). I
have yet to add in hyperlinks and comments.)*

*Posted on 2018-136.076Z*

When I first started learning Haskell, I learned about the Monad instance for Either and immediately got excited. Here, at long last, was a good solution to the error handling problem. When you want exception-like semantics, you can have them, and the rest of the time it’s just a normal value. Later, I learned that the Haskell standard also includes an exception mechanism for the IO type. I was horrified, and confused, but nothing could have prepared me for what I discovered next.

While the standard Haskell exception mechanism infects all of IO it at least has a single, well-defined type for possible errors, with a small number of known cases to handle. GHC extends this with a dynamically typed exception system where any IO value may be hiding any number of unknown and unknowable exception types! Additionally, all manner of programmer errors in pure code (such as pattern match failures and integer division by zero) are thrown into IO when they get used in that context. On top of everything, so-called exceptions can appear that were not thrown by any code you can see but are external to you and your dependencies entirely. There are two classes of these: asynchronous exceptions thrown by the runtime due to a failure in the runtime itself (such as a HeapOverflow) and exceptions thrown due to some impossible-to-meet condition the runtime detects (such as detectable non-termination). Oh, I almost forgot, manually killing a thread or telling the process to exit are also modeled as “exceptions” by GHC.

Once the initial decision to have a dynamically typed exception system was made, everything that could make use of an exception-like semantic in any case was bolted on. What am I going to do, though? Write my own ecosystem and runtime that works how I would prefer? No, I’m going to find a way to make the best of the world I’m in.

When dealing with this situation, there are two separate and equally important things to consider: exception safety, and error handling. Exception safety describes the situation when you are, for example, acquiring and releasing resources (such as file handles). You want to be sure you release the resource, even if the exception system is going to abort your computation unceremoniously. You can never know if this will happen or not, since the runtime can just throw things at you, you always need to wrap resource acquisition/release paths in some exception safety. There are a lot of complex issues here, but it’s not the subject of this post so suffice to say the main pattern of interest for dealing with this is bracket.

Error handling is totally different. This is where you want to be able to recover from possible recoverable errors and do something sensible. Retry, save the task for later, alert the user that their request failed, read from cache when the network is down, whatever.

The first move in this area that I saw that I liked, was the errors package. Many helpers for dealing with error values, and in earlier versions a helper that would exclude unrecoverable errors and convert the rest to error values. I liked this pattern, but wanted more. This is Haskell! I wanted to know, at a type level, when recoverable errors had already been handled. Of course, programmer errors in pure code and unrecoverable errors from the runtime are always possible, so we can’t say anything about them at the type level, but recoverable errors we could know something about. So I wrote a package, iterated a few times, and eventually became a dependency for the helper in the errors package that I had based my whole idea on. Until very recently, errors and unexceptionalio were the two ways I was aware of to handle recoverable errors (and only recoverable errors) reliably, and know at a type level that you had done so. Recently errors decided to change the semantic to fit the previously-misleading documentation of the helper and so unexceptionalio now stands alone (to my knowledge) in this area.

In light of this new reality, I updated the package to make it much more clear (both in documentation and at a type level) what hole in the ecosystem this fills. I exposed the semantic in a few more ways so it can be useful even to people who don’t care about type-level error information. I also named the unrecoverable errors. Things you might want to be safe from, or maybe log and terminate a thread because of, but never recover from. For now, I call these PseudoException.

UnexceptionalIO (when used on GHC) now exposes four instances of Exception that you can use even if you have no use for the rest of the package: ExternalError (for things the runtime throws at you, asynchronously or not), ProgrammerError (for things raised from mistakes in pure code), PseudoException (includes the above and also requests for the process to exit), and SomeNonPseudoException (the negation of the above). All of these will work with the normal GHC catch mechanisms to allow you to easily separate these different uses for the exception system.

From there, the package builds up a type and typeclass with entry and exit points that ensure that values in this type contain no SomeNonPseudoException. The type is only ever used in argument position, all return types are polymorphic in the typeclass (implemented for both UIO and IO, as well as for all monad transformers in the unexceptional-trans package) so that you can use them without having to commit to UIO for your code. If you use the helpers in a program that is all based on IO still, it will catch the exceptions and continue just fine in that context.

Finally, the latest version of the package also exposes some helpers for those cases where you do want to do something with PseudoException. For exception safety, of course, there is bracket, specialized to UIO. For knowing when a thread has terminated (for any reason, success or failure) there is forkFinally, specialized to UIO and PseudoException. Finally, to make sure you don’t accidentally swallow any PseudoException when running a thread, there is fork which will ignore ThreadKilled (you assumedly did that on purpose) but otherwise rethrow PseudoException that terminate a thread to the parent thread.

This is hardly the final word in error handling, but for me, this provides enough sanity that I can handle what I need to in different applications and express my errors at a type level when I want to.
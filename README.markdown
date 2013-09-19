### **Tiger** 0.2.1 by Charles Phillips

**TigerJS** is an expanded port of the popular single-page webapp framework, [SpineJS](https://github.com/spine/spine).  *(Spine is similar to Backbone, although I find it to be more simple, and therefore more flexible and more powerful.)*  Rather than "reinventing the wheel", **TigerJS** builds on production-ready, battle-tested code that has launched countless apps across tech.

**TigerJS** is:

  * **modular** -- TigerJS has a clear separation of concerns (MVC/MVVM), and its libraries can be used singly or as a package.

  * **reusable** -- A TigerJS component for one app is a component for *any* app.  TigerJS uses standard JS design patterns, and modules can be included in Tiger and non-Tiger apps.

  * **simple** -- TigerJS Is Just JavaScript.  It is easy to debug and includes several tools to make Titanium development easy, without obscuring what happens under-the-hood.


*Although the Tiger is built in CoffeeScript, one of the best features of Spine/Tiger's class system is its included shims, providing the same functionality in Vanilla JS as in Coffee.*


**TigerJS** includes inheritance, chainability, complex Model relations, routing, FX/animation lib, AJAX/XHR wrapper, and works on both Android and iOS.  TigerDB module allows auto-persist of models through Titanium's SQL DB!


### Tips:

Require files in this order: `tiger`, `tiger.fx` (optional), `tiger.elements`, others... This allows `tiger.elements` to be switched out, say for a different environment ;), and Tiger.FX to be applied to all Elements.  Tiger requires Spine by default, please include in lib folder.  This version of Spine fixes a remote-model bug as per my pull request.


### Documentation

Please refer to [Spine.js documentation](http://spinejs.com/docs).  Nearly everything that works in Spine, works in Tiger.  Also some extras, like SQLite NoSQL-style storage and One-To-Many Collections.  Element manipulation (add/remove, bind/unbind, events, animation, AJAX get/post) works as in [jQuery](http://api.jquery.com).


### Example App

https://github.com/doublerebel/tigerjs-todo


### Notes:

For build tooling, check out the powerful and excellent [Tintan](http://github.com/doublerebel/tintan), [TSM](http://github.com/russfrank/tsm), and [Node Inspector](https://github.com/dannycoates/node-inspector).  I use Sublime Text 2 and don't miss the Titanium Studio bloat.  In the process of vetting TDD frameworks to add to Tintan's build system, suggestions accepted and appreciated!  Thanks to all Titanium devs who have shared their work and moved the community forward.

Cheers,

**Charles**


MIT Licensed, Copyright 2011 - 2013 Double Rebel

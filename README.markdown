**Tiger** 0.0.2 by Charles Phillips <charles@doublerebel.com>

A library enhancing [Titanium Mobile](https://github.com/appcelerator/titanium_mobile) apps with [Spine](http://maccman.github.com/spine/)'s MVC architecture

Includes inheritance, super constructor, and chainability

Also now includes complex Model relations, routing, FX/animation lib, and bugfixed up-to-date Spine.

TigerDB will persist all models through Titanium's SQL DB!

Tips:

Require files in this order: `tiger`, `tiger.fx` (optional), `tiger.elements`, others... This allows `tiger.elements` to be switched out, say for a different environment ;), and Tiger.FX to be applied to all Elements.  Tiger requires Spine by default, please include in lib folder.  This version of Spine fixes a remote-model bug as per my pull request.

Proper example Todo-list application coming soon.  And please check out the excellent [Tintan](http://github.com/doublerebel/tintan) and [TSM](http://github.com/russfrank/tsm) to avoid Titanium headaches!  I use Sublime Text 2 and don't miss the Titanium Studio bloat.  In the process of vetting TDD frameworks to add to Tintan's build system, suggestions accepted and appreciated!  Thanks to all Titanium devs who have shared their work and moved the community forward.

Cheers,

**Charles**

MIT Licensed, Copyright 2011, 2012 Double Rebel

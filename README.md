# photo-groove

This is a variation on the PhotoGroove application covered in the excellent book Elm In Action (#elm-in-action).

The code started with the `0.19.1` branch and then progressed to include a number of modifications that may or may not be in alignment with the Elm community standards.

The goals of this repository include

- Practice Elm programming
- Determine efficacy of patterns/practices I've used previously such as
  - Dispatch an update function rather than value-based message
  - Optics
  - Type oriented modules

## TL;DR: Value Based Messages Make Sense

See [here for details](MessageAsFunction.md).

I fully expected Message-as-Function + Optics to be _signficantly_ better than value based messages. However, it is within epsilon. The specific requirements will set coefficients of value and determine the best strategy for the project and team. For example, the Function Dispatch technique could be favorable in a situation where

- persisted playback and/or time travelling debugging is not used
- and/or the code base has many long sequential asynchronous workflows with a requirement to update application state _during_ the sequence.

However, I think the Message approach is the default position of the community and there is certainly insufficient evidence from this experiment to challenge that approach.

- Benefits of Functions
  - Ability to update model during sequential asynchronous workflows; as opposed to Tasks which allow constructing sequential asynchronous flows but which result in a single message for the update.
  - Improved locality.
  - Improved combination of functions and effects.
  - Very minor improvement in Parent/Child composition.
  - No discrimination between types used for state and other types.
- Drawbacks of Functions
  - Slightly more difficult onboarding (Learning optics).
  - Bikeshedding: Choosing optics library.
  - Fragmentation: Divergence from standard TEA.
  - Harder to Unit Test UX.
  - Inability to Persist Messages for Playback (ex. to a server).
  - Drastically reduced usefulness of time travelling debugger.

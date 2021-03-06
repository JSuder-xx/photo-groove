# Message as Function

## Benefits

### **Asynchronous Workflows (Minor)**

The one area where I believe Message as Function does shine is asynchronous workflows where the message as function allows for updating the model during the flow (updates during the sequence).

```elm
import Effectful.Core exposing (Updater, updateWithEffect)
import Http


type alias Person = { name : String, bestFriendId : Int, petId : Maybe Int }
type alias Pet = { name : String }

getPersonById : Int -> (Result Http.Error Person -> msg) -> Cmd msg
getPersonById = Debug.todo "getPersonById"

getPetById : Int -> (Result Http.Error Pet -> msg) -> Cmd msg
getPetById = Debug.todo "getPetById"

type alias Model = 
    { message : String
    -- pretend there's a bunch of other stuff here
    }

-- Observe that the message is actually an Updater of Model where the Updater type is: 
-- type Updater a = Updater (a -> (a, Cmd (Updater a)))
type alias Msg = Updater Model

-- Not bothering with lenses here. Just a vanilla update to the message property.
setMessage : String -> Model -> Model
setMessage message model = { model | message = message }

-- Setting the message lifted into an Updater (which can have effect requests, but in this case doesn't).
setMessageEffect : String -> Updater Model
setMessageEffect message = setMessage message |> Effectful.Core.lift

statement : List String -> String
statement words = String.join " " words ++ "."

loadBestFriendsPet : Person -> Updater Model
loadBestFriendsPet person =
    let
        -- local helper because in this example we don't do anything interesting with the error cases
        handleResultWithErrorMessage : List String -> (a -> Updater Model) -> (Result err a -> Updater Model)
        handleResultWithErrorMessage errorMessageWords success result =
            case result of
                Err _ ->
                    setMessageEffect <| statement errorMessageWords

                Ok data ->
                    success data
    in
    updateWithEffect (setMessage ("Loading best friend for " ++ person.name)) <|
        getPersonById person.bestFriendId <|
            handleResultWithErrorMessage ["Error loading best friend id ", String.fromInt person.bestFriendId] <|
                \bestFriend ->
                    case bestFriend.petId of
                        Nothing ->
                            setMessageEffect "The best friend has no pet."

                        Just petId ->
                            updateWithEffect (setMessage ("Loading pet id " ++ String.fromInt petId)) <|
                                getPetById petId <|
                                    handleResultWithErrorMessage ["Failed to load pet id ", String.fromInt petId] <|
                                        \pet ->
                                            setMessageEffect
                                                (statement [ person.name, "'s best friend", bestFriend.name, "'s pet", pet.name ])
```

Now if progress is not required, then the same ultimate result can be achieved using Tasks (and the Task example is more elegant... so there's that).

```elm
loadBestFriendsPet : Person -> Task String { pet : Pet, bestFriend : Person, person : Person }
loadBestFriendsPet person =
    getPersonById person.bestFriendId
        |> Task.mapError (always <| statement [ "Error loading best friend id", String.fromInt person.bestFriendId ])
        |> Task.andThen
            (\bestFriend ->
                bestFriend.petId
                    |> Maybe.map
                        (\petId ->
                            petId
                                |> getPetById
                                |> Task.mapError (always <| statement [ "Failed to load pet id ", String.fromInt petId ])
                        )
                    |> Maybe.withDefault (Task.fail "The best friend has no pet.")
                    |> Task.map (\pet -> { pet = pet, bestFriend = bestFriend, person = person })
            )
```

### **Improved Locality (Minor)**

Both approaches require the same amount of code. In the Message as Value approach there is one line to define the Message case in the union and then one line to match on that case in the `update`.

```elm
type Msg = 
    -- ...Other cases...
    | SomeCommand DataType1 DataType2

SomeCommand argument1 argument2 ->
    -- do some work
```

With the function approach one simply defines a function which is also two lines of code for the signature and the implementation.

```elm
someCommand : DataType1 -> DataType2 -> Model -> Model
someCommand argument1 argument2 =
    -- do the work
```

The signature and implementation are immediately adjacent to one another when using the Function approach and separated when using value-based messages. High locality of related concerns places less cognitive load on developers.

### **Inability to Fail to Handle (Very Very Minor)**

The guidance is to avoid the use of the wildcard `_ ->` in case expressions, but if a developer did use such a catch-all then she might fail to handle a message entirely. I'm not saying. I'm just saying.

### **Combination (Minor)**

Let's say you have one function that updates property X of a model and another that updates property Y of a model. With functions you can combine them

```elm
a [onClick (Model.setX 10 |> Effectful.Core.andThen (always <| Model.setY 20))] []
```

I believe that with Messages as values one would need to either define a custom message for every combination OR create a Batch message case.

### **Consistency of Modeling (Minor)**

When using functions and optics then all types are treated similarly where updates occur via functions exposed on the type's module.

When using messages then types that represent application state offer a single `update` function (accepting a union message) while types that do not provide individual functions per update.

In my opinion, it is cleaner and nicer to have a consistent method. 

### **Parent/Child Composition (Very Minor)**

In terms of effect measured as total lines of code, using Optics to implement parent/child composition requires

- **When** the child is a case/constructor of a union property on a parent model **then** slightly more total lines of code; 17 for Function/15 for Message.
- **When** the child is stored in a property/field on a parent model **then** less total lines of code; 5 for Function/10 for Message.

The Optics approach is slightly more versatile (in that the Lens/Prism can be used for other data spelunking) and shifts the work more into vanilla type oriented programming space (my preference).

Given a parent page that has a model with a shape property of custom type Shape that is one of four different shapes.

```elm
type Model = 
    { shapePage: ShapePage
    }

type ShapePage = 
    CircleShape CirclePage.Model
    | SquareShape SquarePage.Model
    | TriangleShape TrianglePage.Model
    | RhombusShape RhombusPage.Model
```

- And there is both a Model and View for each shape
- And the parent page has defined Optionals (Prisms) for each of the four possible shapes.

```elm
modelCircleOptional : Optional Model CirclePage.Model
modelSquareOptional : Optional Model SquarePage.Model
modelTriangleOptional : Optional Model TrianglePage.Model
modelRhombusOptional : Optional Model RhombusPage.Model
```

- Then the following code would handle displaying the correct shape view and translate the child shape's message into the parent shape's message space.

```elm
view : Model -> Html (Updater Model)
view parentModel =    
    div []
        [ h3 [] [text "Parent Page"] 
        , p [] [text "Below you will see the currently selected shape view"]
        , parentModel 
            |> MaybeEx.oneOf
                [ toParentViewOptional modelCircleOptional CirclePage.view
                , toParentViewOptional modelSquareOptional SquarePage.view
                , toParentViewOptional modelTriangleOptional TrianglePage.view
                , toParentViewOptional modelRhombusOptional RhombusPage.view
                ]
            |> Maybe.withDefault (text "No Found")
        ]
```

A comparison of the lines of code required with each approach.

- The lens approach requires 10 more lines of accessory
  - Message approach requires 5 lines of utility code to convert a parent model and a child model + effect to a parent model + effect.

    ```elm
    toCircle : Model -> ( CirclePage.Model, Cmd CirclePage.Msg ) -> ( Model, Cmd Msg )
    toCircle model ( circle, cmd ) =
        ( { model | shapePage = CirclePage circle }
        , Cmd.map GotCircleMsg cmd
        )
    ```

  - Function approach requires the definition of the lens which is 15 lines of code.

    ```elm
    circleOptional : Optional ShapePage CirclePage.Model
    circleOptional =
        Optional
            (\page ->
                case page of
                    CirclePage m ->
                        Just m

                    _ ->
                        Nothing
            )
            (\m _ -> CirclePage m)

    modelCircleOptional : Optional Model CirclePage.Model
    modelCircleOptional =
        MCompose.lensWithOptional circleOptional shapePageL
    ```

- In the view, the Function approach saves 1 line of code.
  - Message approach requires one line for the match and one line for the handling (with the mapping of the Cmd).
  - Function approach requires one line.

- In the update the function approach saves 7 lines of code as 7 lines are required for Message and 0 for Function.

```elm
GotCircleMsg circleMsg ->
    case model.shapePage of
        CircleShape circle ->
            toCircle model (CirclePage.update circleMsg circle)

        _ ->
            ( model, Cmd.none )
```

- When routing to children (handling Url changes) both Function and the Message approaches require the same amount of code (when creating a helper for the Message case).

## Drawbacks

### **Onboarding (Minor)**

The function dispatch method really shines when combined with Optics, but the use of Optics increases the learning curve for Elm very slightly.

### **Bikeshedding (Very Minor)**

Choosing an Optics library requires making a choice of Optics library.

### **Unit Testing User Interface (Minor)**

Cannot unit test User Interface events by comparing generated Message values due to the inability to compare functions. `Test.Html.Event.expect` is currently designed to compare values. Instead, one would also need to exercise the returned function itself which somewhat breaks the encapsulation of a unit test. In other words, after setup, acting to click, the test would need to verify the final state of the model and not just that an expected Command value was produced.

Given

```elm
startingModel
    |> view
    |> Query.fromHtml
    |> Query.find [ {- Whatever is necessary to find the element -}]
    |> Event.simulate Event.click
```

Then using value-based messages the expectation can be stated simply with

```elm
    |> Event.expect (SomeExpectedMessage "Some Expected Data")
```

With function-based messages then we would instead need to write

```elm
    |> (\updateFunctionEvent ->
            case Event.toResult updateFunctionEvent |> Result.withDefault identity of
                updateFunction ->
                    Expect.equal 
                        ( startingModel, Cmd.none ) -- here we would assert that the model was what we expected as well as the command
                        (updatefunction startingModel)
        )
```

### **Persisted Playback (Moderate)**

When messages are represented as values they can be serialized, saved, and played back at a later date.

### **Message Visibility in Time Travelling Debugger (Moderate)**

The time travelling debugger is close to useless since the Message as function is opaque.

### **Background Worker or Server Processing (Minor)**

By dispatching functions instead of messages it would not be possible for the Elm architecture to execute updates in a worker.

- As of 0.19.1, I believe Elm runs everything in the UI thread. However, logically the Elm architecture seems to support the UI sending messages to a worker, running the update inside the worker, and serializing the model back to the UI thread.
- I would guess that Elm does not offer this now because the number of cases where that would make sense is limited to cases where the cost of the serialization is significantly less than the cost of the computation (  otherwise there would be no real increase in responsiveness and a total increase in CPU watts consumed with the additional overhead of serialization). Therefore, I would suspect that even if Elm eventually offered such a capability that it would likely be an option.

# Live Partial Usage Guide

LivePartial allows you to create dynamic, real-time updating partial views in your Rails application with minimal setup. Updates are automatically synced between all connected clients via WebSockets.

## Features
- Simple state management - just update state properties to trigger re-renders
- Real-time updates - changes sync automatically across all clients
- Event system for lifecycle hooks
- Works with your existing Rails partials
- Supports both JS-driven and backend updates
- No complex configuration needed

 ##  ⚠️ This is early, work in progress
 Not production ready.

## Installation
Prerequisites:
- Rails 6+
- ActionCable
- Supports ESBuild or Webpacker

1. Add to your Gemfile:
```ruby
gem 'live_partial', github: 'iamcoreyg/live-partial'
```

2. Run bundle install:
```bash
bundle install
```

3. Run the installer:
```bash
rails generate live_partial:install
```


## Basic Setup

1. First, include LivePartial in your controller:

```ruby
class HomeController < ApplicationController
  include LivePartial::Controller
end
```

2. Render your live partial in the view:

```erb
<%= live_render "path/to/partial",
  id: "color-picker",
  state: { color: "red" }
%>
```

3. Define your partial template:

```erb
# _partial.html.erb
<div id="<%= id %>">
  <input type="color" value="<%= state.color %>" />
  Current color: <%= state.color %>
</div>
```

## JavaScript Updates

For JavaScript-driven updates, use the simple state API:

```javascript
// Get a reference to your partial
const picker = livePartial('color-picker')

// Update state - automatically triggers re-render
picker.state.color = 'blue'

// Listen for events
picker.on('afterRender', (event) => {
  console.log('Updated with:', event.state)
})
```

Controller stays minimal:
```ruby
def update
  live_render(state: params[:state])
end
```

## Backend Updates

For form submissions or backend-triggered updates, use the explicit render format:

```ruby
def create
  @todo = Todo.create(todo_params)

  live_render 'todos/list',
    id: 'todo-list',
    state: { todos: Todo.all }
end
```

## Event System

LivePartial emits events during the update lifecycle:

```javascript
beforeRender - Before the partial is re-rendered
afterRender - After the partial is re-rendered
error - If there is an error during rendering
stateChange - When any state property changes
```

## Required Options

When using `live_render`, these options are required:
- `id`: Unique identifier for the partial

Optional options:
- `state`: Initial state hash (default: {})
- `for`: Associated resource for the partial
- Any additional options are passed as locals to the partial

## Notes
- WebSocket updates are handled automatically via Action Cable
- Keep partials focused and single-purpose for best performance
- State is synchronized across all clients viewing the same partial
- All state updates flow through your Rails controller for security

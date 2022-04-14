# Dependency Injection for Active Operation

Dependency injection is a stigmatized term. It's often associated with large, convoluted enterprise software. However, dependency injection doesn't have to be heavyweight or complicated. Lightweight frameworks allow you to reap all the benefits of dependency injection without introducing cruft and complexity. Using dependency injection can lead to much more modular and maintainable code bases.

In this example, we're using `Dry::Container` for dependency injection into `ActiveOperation` instances. We being by defining the container that will manage our injected dependencies:

```ruby
class Container
  extend Dry::Container::Mixin

  register :db do
    DB.new(File.expand_path('../db.json', __FILE__))
  end
end
```

In this case, we have a single dependency, a database, which itself has a very straightforward implementation:

```ruby
DB = Struct.new(:path) do
  def count
    load.count
  end

  def list
    load
  end

  def get(id)
    load[id]
  end

  def add(id, data)
    update { |db| db.merge(id => data) }
  end

  def remove(id)
    update { |db| db.reject { |k, _| k == id } }
  end

  private

  def update
    File.write(path, JSON.pretty_generate(load.tap { yield }))
  end

  def load
    JSON.parse(File.read(path))
  end
end
```

Our database is essentially a trivial key value store that persists all its data in `db.json`.

Next, we define an operation base class with a convenience method for resolving dependencies:

```ruby
class Operation < ActiveOperation::Base
  def self.resolve(name) = -> { Container[name] }
end
```

Now we're ready to define operations that utilize dependency injection. For the sake of this example, lets assume that we're modelling a business process for creating users.

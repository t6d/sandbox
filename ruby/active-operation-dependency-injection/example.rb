require 'dry-container'
require 'active_operation'
require 'stringio'
require 'dry/container/stub'
require 'minitest/autorun'

class Operation < ActiveOperation::Base
  def self.resolve(name) = -> { Container[name] }
end

class Container
  extend Dry::Container::Mixin

  register :db do
    DB.new(File.expand_path('../db.json', __FILE__))
  end
end

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

class InMemory
  def initialize
    @db = {}
  end

  def count
    @db.count
  end

  def list
    @db
  end

  def get(id)
    @db[id]
  end

  def add(id, data)
    @db[id] = data
  end

  def remove(id)
    @db.reject! { |k, _| k == id }
  end
end

class CreateUser < Operation
  property! :name, accepts: String
  property! :db, default: resolve(:db)

  def execute
    db.add(1, { name: name })
  end
end

class CreateUserTest < MiniTest::Test
  def setup
    Container.enable_stubs!
  end

  def test_logging
    with_stubbed_db do |db|
      CreateUser.perform(name: 'John')
      assert_equal 1, db.count
      assert_equal db.get(1), { name: 'John' }
    end
  end

  def with_stubbed_db
    yield InMemory.new.tap { |db| Container.stub(:db, db) }
  ensure
    Container.unstub(:db)
  end
end

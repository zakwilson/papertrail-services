class Pluralize
  attr_reader :singular, :plural, :count, :omit_count

  def initialize(singular, options = {})
    @singular   = singular
    @plural     = options.fetch(:plural, singular.pluralize)
    @count      = options.fetch(:count)
    @omit_count = options.fetch(:omit_count, false) == true
  end

  def to_s
    count_label + pluralized
  end

  private

  def count_label
    return "" if omit_count
    "#{count} "
  end

  def pluralized
    return singular if count == 1
    plural
  end
end

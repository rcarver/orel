module Orel
  module QueryBatches
    # Public: Specify that you want the results to be queried in batches.
    #
    # options - Hash of options.
    #           :size  - Number of rows to query in each batch (default: 1000).
    #           :group - Boolean whether to enumerate results individually or by batch.
    #           :order - Boolean whether to order the query by the key, or leave to natural order.
    #
    # Returns nothing.
    def query_batches(options)
      @batch_size = options.delete(:size) || 1000
      @batch_group = options.delete(:group) || false
      @batch_order = options.key?(:order) ? options.delete(:order) : true
      raise ArgumentError, "Unknown options: #{options.keys.inspect}" if options.any?
    end
  end
end

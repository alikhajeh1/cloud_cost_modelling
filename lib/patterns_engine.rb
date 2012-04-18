class PatternsEngine
  # Processes the patterns and returns an array of values, one for each month between the start and end dates
  def self.get_monthly_results(monthly_baseline, patterns, start_date, end_date)
    results = []
    current_month = start_date
    # Loop through the months between start and end date
    while current_month <= end_date
      # Set the current month's usage to the baseline
      current_result = monthly_baseline

      # Process the patterns by applying their rules to the current month
      patterns.each do |pattern|
        pattern.rules.each do |rule|
          # There's a bug with time_diff gem and leap years, which shows the diff as 4 weeks rather than 1 month in feb of leap years,
          # e.g. try Time.diff between Feb-2012 and Mar-2012. We can add 15 days to the current_month to make sure it forces the diff
          # to return 1 month, but don't add this 15 days to the current_month variable as overtime it can carry over to the next month
          current_result = apply_rule(start_date, current_month + 15.days, current_result, rule)
          # Update the monthly_baseline if it's a permanent rule
          monthly_baseline = current_result if rule.rule_type.downcase == 'permanent'
        end
      end

      # Convert BigDecimals to Floats to simplify calculations done on the results
      results << current_result.to_f
      current_month += 1.month
    end

    results
  end

  private
  def self.apply_rule(start_date, current_month, current_result, rule)
    if rule.applicable?(start_date, current_month)
      case rule.variation
        when '='
          current_result = rule.value
        when '+'
          current_result += rule.value
        when '-'
          current_result -= rule.value
        when '*'
          current_result *= rule.value
        when '/'
          current_result /= rule.value
        when '^'
          current_result **= rule.value.to_f # Need to convert BigDecimal to Float for exponentiation
      end
    end

    current_result
  end

end
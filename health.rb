class Health
  def track time, specimen, measurements
    p [time, specimen, measurements]
  end
end

module HealthHelper
  refine Kernel do
    def track *args
      $health.track *args
    end
  end
end

$health = Health.new
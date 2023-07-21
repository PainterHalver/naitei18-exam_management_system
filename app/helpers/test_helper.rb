module TestHelper
  def set_time
    @remaining_time = Time.at(@test.subject.test_duration * 60)
                          .utc.strftime("%H:%M:%S")
  end

  def set_end_time
    @end_time = Time.now.to_i + @test.subject.test_duration * 60
  end
end

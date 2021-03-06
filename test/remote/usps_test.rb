require File.dirname(__FILE__) + '/../test_helper'

class USPSTest < Test::Unit::TestCase
  include ActiveMerchant::Shipping
  
  def setup
    @packages               = ActiveMerchant::Shipping::TestFixtures.packages.dup
    @locations              = ActiveMerchant::Shipping::TestFixtures.locations.dup
    @carrier                = USPS.new(fixtures(:usps))
    
  end
  
  def test_zip_to_zip
    assert_nothing_raised do
      response = @carrier.find_rates( Location.new(:zip => 40524),
                                      Location.new(:zip => 40515),
                                      Package.new(16, [12,6,2], :units => :imperial))
    end
  end
  
  def test_just_country_given
    assert_nothing_raised do
      response = @carrier.find_rates( @locations[:beverly_hills],
                                      Location.new(:country => 'CZ'),
                                      Package.new(100, [5,10,20]))
    end
  end
  
  def test_us_to_canada
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(  @locations[:beverly_hills],
                                  @locations[:ottawa],
                                  @packages.values_at(:wii),
                                  :test => true)
    assert_not_equal [], response.rates.length
    end
  end
  
  def test_domestic_rates_thoroughly
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(  @locations[:new_york],
                                  @locations[:beverly_hills],
                                  @packages.values_at(:book,:wii),
                                  :test => true)
    end
    assert response.success?, response.message
    assert_instance_of Hash, response.params
    assert_instance_of String, response.xml
    assert_instance_of Array, response.rates
    assert_not_equal [], response.rates
    
    rate = response.rates.first
    assert_equal 'USPS', rate.carrier
    assert_equal 'USD', rate.currency
    assert_instance_of Fixnum, rate.total_price
    assert_instance_of Fixnum, rate.price
    assert_instance_of String, rate.service_name
    assert_instance_of String, rate.service_code
    assert_instance_of Array, rate.package_rates
    assert_equal @packages.values_at(:book, :wii), rate.packages
    
    package_rate = rate.package_rates.first
    assert_instance_of Hash, package_rate
    assert_instance_of Package, package_rate[:package]
    assert_not_nil package_rate[:rate]
    
    other_than_two = response.rates.map(&:package_count).reject {|n| n == 2}
    assert_equal [], other_than_two, "Some RateEstimates do not refer to the right number of packages (#{other_than_two.inspect})"
    
    
  end
  
  def test_international_thoroughly
    
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(  @locations[:beverly_hills],
                                  @locations[:ottawa],
                                  @packages.values_at(:book, :wii),
                                  :test => true)
    end
    
    assert response.success?, response.message
    assert_instance_of Hash, response.params
    assert_instance_of String, response.xml
    assert_instance_of Array, response.rates
    assert_not_equal [], response.rates
    
    rate = response.rates.first
    assert_equal 'USPS', rate.carrier
    assert_equal 'USD', rate.currency
    assert_instance_of Fixnum, rate.total_price
    assert_instance_of Fixnum, rate.price
    assert_instance_of String, rate.service_name
    assert_instance_of String, rate.service_code
    assert_instance_of Array, rate.package_rates
    assert_equal @packages.values_at(:book, :wii), rate.packages
    
    package_rate = rate.package_rates.first
    assert_instance_of Hash, package_rate
    assert_instance_of Package, package_rate[:package]
    assert_not_nil package_rate[:rate]
    
    other_than_two = response.rates.map(&:package_count).reject {|n| n == 2}
    assert_equal [], other_than_two, "Some RateEstimates do not refer to the right number of packages (#{other_than_two.inspect})"
    
  end
  
  def test_bare_packages
    response = nil
    p = Package.new(0,0)
    response = begin
      @carrier.find_rates( @locations[:beverly_hills], # imperial (U.S. origin)
                                  @locations[:ottawa],
                                  p, :test => true)
    rescue ResponseError => e
      e.response
    end
    assert response.success?, response.message
  end
end
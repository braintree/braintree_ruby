Project.configure do |project|
  case project.name
  when /client_library_ruby_unit/
    project.build_command = "rake spec:unit --trace"
  when "client_library_ruby_integration_master"    
    project.build_command = "CRUISE_BUILD=#{project.name} GATEWAY_PORT=3010 SPHINX_PORT=3322 rake run_integration_specs_for_cruise --trace"
    project.triggered_by :gateway_master
  when "client_library_ruby_integration_release_1"
    project.build_command = "CRUISE_BUILD=#{project.name} GATEWAY_PORT=3020 SPHINX_PORT=3332 rake run_integration_specs_for_cruise --trace"
    project.triggered_by :gateway_release_1
  end
end

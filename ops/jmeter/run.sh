docker run --platform linux/amd64 --rm -v $(pwd):/test-plan -w /test-plan justb4/jmeter:5.5 -n -t test-plan.jmx -l results.jtl

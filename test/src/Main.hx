class Main
{
    static function main()
	{
		var runner = new utest.Runner();
		
        runner.addCase(new BaseTests());
		runner.addCase(new ExtTests());
		runner.addCase(new MapTests());
		runner.addCase(new DateTests());
		runner.addCase(new EnumTests());

        utest.ui.Report.create(runner);
        runner.run();
	}
}

class Main
{
    static function main()
	{
		var runner = new utest.Runner();
		
        runner.addCase(new BaseTests());
		runner.addCase(new ExtTests());

        utest.ui.Report.create(runner);
        runner.run();
	}
}

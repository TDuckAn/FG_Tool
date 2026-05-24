using System;
using System.Text;
using FuGradeHelper.Commands;

Console.OutputEncoding = Encoding.UTF8;
Console.InputEncoding = Encoding.UTF8;

if (args.Length == 0)
{
    PrintUsage();
    return 1;
}

switch (args[0].ToLowerInvariant())
{
    case "parse-fg":
        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: FuGradeHelper.exe parse-fg <path-to-file.fg>");
            return 1;
        }
        return ParseFgCommand.Run(args[1]);

    case "write-cmt":
        return WriteCmtCommand.Run(
            jsonData: GetArg(args, "--data") ?? GetArg(args, "--data-file"),
            outputPath: GetArg(args, "--output"));

    case "read-cmt":
        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: FuGradeHelper.exe read-cmt <path-to-file.cmt>");
            return 1;
        }
        return ReadCmtCommand.Run(args[1]);

    case "inspect-cmt":
        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: FuGradeHelper.exe inspect-cmt <path-to-file.cmt>");
            return 1;
        }
        return InspectCmtCommand.Run(args[1]);

    case "write-fg":
        return WriteFgCommand.Run(
            inputPath: GetArg(args, "--input"),
            gradesFilePath: GetArg(args, "--grades-file"),
            outputPath: GetArg(args, "--output"));

    default:
        Console.Error.WriteLine($"Unknown command: {args[0]}");
        PrintUsage();
        return 1;
}

static string GetArg(string[] args, string flag)
{
    for (int i = 0; i < args.Length - 1; i++)
        if (args[i].Equals(flag, StringComparison.OrdinalIgnoreCase))
            return args[i + 1];
    return null;
}

static void PrintUsage()
{
    Console.Error.WriteLine("FuGradeHelper - FuGrade .fg parser and .cmt writer");
    Console.Error.WriteLine();
    Console.Error.WriteLine("Commands:");
    Console.Error.WriteLine("  parse-fg <path.fg>                      Parse .fg file, output JSON to stdout");
    Console.Error.WriteLine("  write-fg --input <path.fg> --grades-file <scores.json> --output <path.fg>");
    Console.Error.WriteLine("  write-cmt --data <json> --output <path> Write .cmt binary from JSON input");
}

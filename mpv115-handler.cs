using System;
using System.Collections.Generic;
using System.Diagnostics;

internal static class Program
{
    private const string Mpv = @"__MPV_EXE__";

    [STAThread]
    private static void Main(string[] args)
    {
        try
        {
            if (args.Length != 1) return;
            var uri = new Uri(args[0]);
            if (uri.Scheme != "mpv115" || uri.Host != "play") return;

            var query = ParseQuery(uri.Query);
            Uri media;
            if (!query.ContainsKey("url") || !Uri.TryCreate(query["url"], UriKind.Absolute, out media) || media.Scheme != "https") return;
            if (!IsAllowedMedia(media)) return;
            if (!System.IO.File.Exists(Mpv)) return;

            var title = Clean(query.ContainsKey("title") ? query["title"] : "", 160);
            var userAgent = Clean(query.ContainsKey("ua") ? query["ua"] : "", 300);
            var arguments = "--referrer=https://115.com/ " +
                "--user-agent=\"" + userAgent + "\" " +
                "--force-media-title=\"" + title + "\" --force-window=yes \"" + media.AbsoluteUri + "\"";

            Process.Start(new ProcessStartInfo
            {
                FileName = Mpv,
                Arguments = arguments,
                UseShellExecute = false,
                CreateNoWindow = true
            });
        }
        catch { }
    }

    private static Dictionary<string, string> ParseQuery(string query)
    {
        var result = new Dictionary<string, string>();
        foreach (var pair in query.TrimStart('?').Split('&'))
        {
            var parts = pair.Split(new[] { '=' }, 2);
            if (parts.Length == 2)
                result[Decode(parts[0])] = Decode(parts[1]);
        }
        return result;
    }

    private static string Decode(string value)
    {
        return Uri.UnescapeDataString(value.Replace('+', ' '));
    }

    private static string Clean(string value, int maxLength)
    {
        value = value.Replace("\r", "").Replace("\n", "").Replace("\"", "'");
        return value.Substring(0, Math.Min(maxLength, value.Length));
    }

    private static bool IsAllowedMedia(Uri media)
    {
        var host = media.Host.ToLowerInvariant();
        var path = media.AbsolutePath;
        if (!path.EndsWith(".m3u8", StringComparison.OrdinalIgnoreCase)) return false;
        return host == "115.com" || host.EndsWith(".115.com") ||
            host == "115cdn.net" || host.EndsWith(".115cdn.net");
    }
}

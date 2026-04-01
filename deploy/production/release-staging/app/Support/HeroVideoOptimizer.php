<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Symfony\Component\Process\Process;

class HeroVideoOptimizer
{
    public function optimizeAndStore(UploadedFile $file, string $directory = 'landing/hero-videos'): array
    {
        $disk = Storage::disk('public');
        $disk->makeDirectory($directory);

        $outputRelativePath = trim($directory, '/') . '/' . Str::uuid() . '.mp4';
        $outputAbsolutePath = $disk->path($outputRelativePath);

        $process = new Process([
            $this->resolveBinary(),
            '-y',
            '-i',
            $file->getRealPath(),
            '-an',
            '-vf',
            'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black',
            '-c:v',
            'libx264',
            '-preset',
            'medium',
            '-profile:v',
            'high',
            '-level',
            '4.1',
            '-pix_fmt',
            'yuv420p',
            '-movflags',
            '+faststart',
            '-crf',
            '24',
            '-maxrate',
            '3500k',
            '-bufsize',
            '7000k',
            '-r',
            '24',
            $outputAbsolutePath,
        ]);

        $process->setTimeout(300);
        $process->run();

        if (! $process->isSuccessful()) {
            if (is_file($outputAbsolutePath)) {
                @unlink($outputAbsolutePath);
            }

            throw new RuntimeException('FFmpeg gagal mengoptimasi video hero.');
        }

        return [
            'path' => $outputRelativePath,
            'mime' => 'video/mp4',
        ];
    }

    private function resolveBinary(): string
    {
        $configured = (string) config('services.ffmpeg.binary', '');
        $fallbackBinary = 'C:\\Users\\Sagita Priscilia R\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-8.1-full_build\\bin\\ffmpeg.exe';

        if ($configured !== '' && is_file($configured)) {
            return $configured;
        }

        if (is_file($fallbackBinary)) {
            return $fallbackBinary;
        }

        return 'ffmpeg';
    }
}

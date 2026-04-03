<?php

namespace App\Http\Controllers;

use App\Models\CareerApplication;
use App\Models\GlobalSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class CareerApplicationController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $socialHub = GlobalSetting::masterSocialHub();
        $careersPage = data_get($socialHub, 'careers_page', []);
        $cards = collect(data_get($careersPage, 'cards', []));
        $fields = collect(data_get($careersPage, 'form_fields', []));
        $jobTitle = trim((string) $request->input('job_title', ''));

        if ($jobTitle === '' || ! $cards->contains(fn ($card) => trim((string) data_get($card, 'title', '')) === $jobTitle)) {
            throw ValidationException::withMessages([
                'job_title' => 'Posisi yang dipilih tidak valid.',
            ]);
        }

        $rules = [
            'job_title' => ['required', 'string', 'max:255'],
        ];

        foreach ($fields as $field) {
            $key = trim((string) data_get($field, 'key', ''));
            $type = trim((string) data_get($field, 'type', 'text'));
            $required = (bool) data_get($field, 'required', false);

            if ($key === '') {
                continue;
            }

            $fieldRules = $required ? ['required'] : ['nullable'];

            switch ($type) {
                case 'email':
                    $fieldRules[] = 'email';
                    $fieldRules[] = 'max:255';
                    break;
                case 'tel':
                    $fieldRules[] = 'string';
                    $fieldRules[] = 'max:50';
                    break;
                case 'textarea':
                    $fieldRules[] = 'string';
                    $fieldRules[] = 'max:5000';
                    break;
                case 'select':
                    $options = collect(data_get($field, 'options', []))
                        ->map(fn ($option) => trim((string) $option))
                        ->filter()
                        ->values()
                        ->all();
                    $fieldRules[] = 'string';
                    if ($options !== []) {
                        $fieldRules[] = 'in:' . implode(',', array_map(fn ($value) => str_replace(',', '\,', $value), $options));
                    }
                    break;
                case 'file':
                    $fieldRules[] = 'file';
                    $fieldRules[] = 'max:5120';
                    break;
                default:
                    $fieldRules[] = 'string';
                    $fieldRules[] = 'max:255';
                    break;
            }

            $rules['fields.' . $key] = $fieldRules;
        }

        $validated = $request->validate($rules);
        $responses = [];
        $uploadedFiles = [];
        $storedPaths = [];

        try {
            foreach ($fields as $field) {
                $key = trim((string) data_get($field, 'key', ''));
                $label = trim((string) data_get($field, 'label', $key));
                $type = trim((string) data_get($field, 'type', 'text'));

                if ($key === '') {
                    continue;
                }

                if ($type === 'file') {
                    $file = data_get($validated, 'fields.' . $key);
                    if (! $file) {
                        continue;
                    }

                    $path = $file->store('career-applications', 'public');
                    $storedPaths[] = $path;
                    $uploadedFiles[$key] = [
                        'label' => $label,
                        'path' => $path,
                        'original_name' => $file->getClientOriginalName(),
                    ];
                    continue;
                }

                $value = data_get($validated, 'fields.' . $key);
                if ($value === null || $value === '') {
                    continue;
                }

                $responses[$key] = [
                    'label' => $label,
                    'value' => $value,
                ];
            }

            CareerApplication::query()->create([
                'job_title' => $jobTitle,
                'responses' => $responses,
                'uploaded_files' => $uploadedFiles,
                'status' => 'submitted',
            ]);
        } catch (\Throwable $exception) {
            foreach ($storedPaths as $path) {
                if (Storage::disk('public')->exists($path)) {
                    Storage::disk('public')->delete($path);
                }
            }

            throw $exception;
        }

        return response()->json([
            'message' => 'Lamaran berhasil dikirim.',
        ], 201);
    }
}

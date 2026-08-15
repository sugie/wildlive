<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class KeepCapturedAnimalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, array<int, string>> */
    public function rules(): array
    {
        return [
            // Optional: a blank name falls back to the species name in the
            // Application Layer rather than being rejected here.
            'name' => ['nullable', 'string', 'max:64'],
        ];
    }
}

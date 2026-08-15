<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StartExpeditionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, array<int, string>> */
    public function rules(): array
    {
        return [
            'map_id' => ['required', 'string', 'max:64'],
            'hunter_id' => ['required', 'string', 'max:64'],
            // Requesting the development shortcut. Whether it is granted is
            // decided by DevExpeditionPolicy, not by this validation rule.
            'dev_instant_resolve' => ['sometimes', 'boolean'],
        ];
    }
}

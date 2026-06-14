<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    protected $table = 'users';

    public $timestamps = false;

    protected $fillable = [
        'username', 'password', 'full_name', 'role',
        'total_xp', 'xp', 'streak_count', 'last_login_date',
        'avatar', 'violation_count', 'banned_until', 'is_locked',
    ];

    protected $hidden = ['password'];

    protected $casts = [
        'banned_until' => 'datetime',
        'last_login_date' => 'date',
        'is_locked' => 'boolean',
    ];
}
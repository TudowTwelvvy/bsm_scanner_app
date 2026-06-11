using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace api.DTOs.Auth
{
    public class RegisterReqDto
    {
        [Required] // Cannot be null
        [MaxLength(255)] // VARCHAR(255)
        [EmailAddress]
       public string Email { get; set; } = string.Empty;
       [Required]
       [MinLength(6)]
       public string Password { get; set; } = string.Empty;
       public string? DisplayName { get; set; }
    }
}
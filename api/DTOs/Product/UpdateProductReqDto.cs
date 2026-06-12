using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace api.DTOs.Product
{
    public class UpdateProductReqDto
    {
        [MaxLength(255)]
        public  string? ProductName { get; set; }
        [MaxLength(1000)]
        public string? Notes { get; set; }
    }
}
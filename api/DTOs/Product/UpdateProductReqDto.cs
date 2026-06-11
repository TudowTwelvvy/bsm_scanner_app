using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace api.DTOs.Product
{
    public class UpdateProductReqDto
    {
        public  string? ProductName { get; set; }
        public string? Notes { get; set; }
    }
}
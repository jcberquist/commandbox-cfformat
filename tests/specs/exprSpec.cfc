component extends=tests.FormatBaseSpec {

    function run() {
        describe('The collectExpr() function', function() {
            it('continues after a new line with a binary operator', function() {
                var tokens = loadExprTokens('binaryoperator');
                expect(tokens[tokens.len() - 1][1]).toBe('2');
                var tokens = loadExprTokens('group');
                expect(tokens[tokens.len() - 1][1]).toBe('3');
            });
            it('continues if previous line ended with binary operator', function() {
                var tokens = loadExprTokens('precedingoperator');
                expect(tokens[tokens.len() - 1][1]).toBe('2');
            });
            it('continues after a new line with a ternary operator', function() {
                var tokens = loadExprTokens('ternary');
                expect(tokens[tokens.len() - 1][1]).toBe('3');
            });
            it('continues if previous line ended with ternary operator', function() {
                var tokens = loadExprTokens('precedingoperator');
                expect(tokens[tokens.len() - 1][1]).toBe('2');
            });
            it('does not consume a following if statement', function() {
                var tokens = loadExprTokens('if');
                expect(tokens.last()[1]).notToBe('if');
            });
            it('collects a function call in an expression', function() {
                var tokens = loadExprTokens('withfunction');
                var token = tokens[tokens.len() - 1];
                expect(token).toBeTypeOf('struct');
                expect(token.type).toBe('function-call');
            });
            it('collects chained method calls', function() {
                var tokens = loadExprTokens('accessor');
                var token = tokens[tokens.len() - 1];
                expect(token).toBeTypeOf('struct');
                expect(token.type).toBe('function-call');
                expect(tokens[tokens.len() - 2][1]).toBe('c');
            });
        });
    }

}
